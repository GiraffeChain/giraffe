import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:fixnum/fixnum.dart';
import 'package:giraffe_protocol/protocol.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:giraffe_testnet_simulator/droplets.dart';
import 'package:giraffe_testnet_simulator/log.dart';
import 'package:giraffe_testnet_simulator/simulation_record.dart';
import 'package:rxdart/rxdart.dart';

import 'simulation_status.dart';

class Simulator {
  final int stakerCount;
  final int relayCount;
  final Duration duration;
  final String digitalOceanToken;
  SimulationStatus status = SimulationStatus_Initializing();

  Simulator(
      {required this.stakerCount,
      required this.relayCount,
      required this.duration,
      required this.digitalOceanToken});

  Future<void> run() async {
    final random = Random.secure();
    seed() => List.generate(32, (_) => random.nextInt(255));
    final lockAddress = await PrivateTestnet.defaultLockAddress;
    log.info("Generating $stakerCount stakers");
    final initializers = await Future.wait(List.generate(
        stakerCount,
        (_) async =>
            StakingAccount.generate(Int64(1000000), lockAddress, seed())));
    final startTime = DateTime.now()
        .add(Duration(seconds: 16) *
            relayCount) // VM creation time; relays created sequentially in order to capture IP address for peers
        .add(Duration(seconds: 150)) // Relay Time-to-ready
        .add(Duration(seconds: 136)); // Stakers created in parallel
    log.info("Setting genesis timestamp to $startTime");
    final genesis = GenesisConfig(
      Int64(startTime.millisecondsSinceEpoch),
      initializers.map((i) => i.transaction).toList(),
      [0],
      ProtocolSettings.defaultAsMap,
    ).block;
    log.info("Genesis id=${genesis.header.id.show}");
    log.info(
        "Genesis settings ${genesis.header.settings.entries.map((e) => "${e.key}=${e.value}").join(" ")}");
    final server = SimulatorHttpServer(
      genesis: genesis,
      status: () => status,
    );
    // No await
    server.run();
    final simulationId = "sim${DateTime.now().millisecondsSinceEpoch}";
    log.info("Simulation id=$simulationId");
    final ip = await publicIp();
    log.info("You can view the status and results at http://$ip:8080/status");
    try {
      final relays = await launchRelays(ip, simulationId, genesis);
      await launchStakers(simulationId, initializers, relays);
      log.info("Waiting until genesis");
      await Future.delayed(startTime
          .subtract(const Duration(seconds: 10))
          .difference(DateTime.now()));
      final runningStatus = SimulationStatus_Running(records: []);
      status = runningStatus;
      final sub = recordsStream(relays).listen(
        (record) {
          log.info(
              "Recording block id=${record.blockId} height=${record.height} slot=${record.slot} droplet ${record.dropletId}");
          runningStatus.records.add(record);
        },
        onError: (e, s) {
          log.severe("Error in simulation record stream", e, s);
        },
        onDone: () => log.info("Simulation record stream done"),
      );
      log.info("Running simulation for $duration");
      await Future.delayed(duration);
      await sub.cancel();
      status = SimulationStatus_Completed(records: runningStatus.records);
      log.info(
          "Mission complete. The simulation server will stay alive until manually stopped. View the results at http://$ip:8080/status");
    } finally {
      log.info("Deleting droplets");
      await deleteSimulationDroplets(digitalOceanToken);
      log.info("Droplets deleted.");
    }
  }

  Future<List<RelayDroplet>> launchRelays(
      String ip, String simulationId, FullBlock genesis) async {
    log.info("Simulation public ip=$ip");
    final genesisUrl = "http://$ip:8080/genesis/${genesis.header.id.show}.pbuf";
    log.info("Using genesis at $genesisUrl");
    log.info("Launching $relayCount relay droplets");
    final containers = <RelayDroplet>[];
    try {
      for (int i = 0; i < relayCount; i++) {
        final List<String> peers;
        if (i == 0) {
          peers = [];
        } else if (i == 1) {
          peers = [containers[0].ip];
        } else {
          peers = [containers[i - 1].ip, containers[i - 2].ip];
        }
        final container = await RelayDroplet.create(
          simulationId,
          i,
          digitalOceanToken,
          genesisUrl,
          peers.map((p) => "$p:2023").toList(),
        );
        containers.add(container);
      }
      log.info("Awaiting blockchain API ready");
      for (final container in containers) {
        await retryableFuture(
          () async {
            final response = await httpClient
                .get(Uri.parse("http://${container.ip}:2024/api"));
            if (response.statusCode != 200) {
              throw StateError(
                  "Failed to connect to relay http://${container.ip}:2024/api");
            }
          },
          retries: 60 * 5,
        );
      }
    } catch (e, s) {
      log.severe("Failed to launch relays", e, s);
      for (final container in containers) {
        await deleteDroplet(container.id);
      }
      rethrow;
    }
    return containers;
  }

  Future<List<StakingDroplet>> launchStakers(String simulationId,
      List<StakingAccount> initializers, List<RelayDroplet> relays) async {
    log.info("Launching $stakerCount staker droplets");
    final containerFutures = <Future<StakingDroplet>>[];
    for (int i = 0; i < initializers.length; i++) {
      final initializer = initializers[i];
      containerFutures.add(StakingDroplet.create(
        simulationId,
        i,
        digitalOceanToken,
        initializer,
        relays[Random().nextInt(relays.length)],
      ));
    }
    try {
      return Future.wait(containerFutures);
    } catch (e, s) {
      log.severe("Failed to launch stakers", e, s);
      await Future.wait(containerFutures
          .map((f) => f.then((c) => deleteDroplet(c.id)).voidError));
      Future.wait(relays.map((r) => deleteDroplet(r.id)));
      rethrow;
    }
  }

  Future<void> deleteDroplet(String id) async {
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $digitalOceanToken",
    };
    final response = await httpClient.delete(
      Uri.parse("https://api.digitalocean.com/v2/droplets/$id"),
      headers: headers,
    );
    assert(response.statusCode < 300,
        "Failed to create container. status=${response.statusCode}");
  }
}

class SimulatorHttpServer {
  final FullBlock genesis;
  final SimulationStatus Function() status;

  SimulatorHttpServer({required this.genesis, required this.status});

  Future<void> run() async {
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
    final idStr = genesis.header.id.show;
    await for (final request in server) {
      final response = request.response;
      if (request.uri.path == "/genesis/$idStr.pbuf") {
        response.add(genesis.writeToBuffer());
      } else if (request.uri.path == "/status") {
        response.write(jsonEncode(status().toJson()));
      }
      await response.close();
    }
  }
}

Future<String> publicIp() async {
  final response = await httpClient.get(
    Uri.parse("https://checkip.amazonaws.com"),
  );
  assert(response.statusCode < 300,
      "Failed to get public IP. status=${response.statusCode}");
  final payload = utf8.decode(response.bodyBytes);
  final split = payload.split(',');
  return split.last.trim();
}

Stream<SimulationRecord> recordsStream(List<RelayDroplet> relays) =>
    MergeStream(relays.map((r) => relayRecordsStream(r)));

Stream<SimulationRecord> relayRecordsStream(RelayDroplet relay) => Stream.value(
        BlockchainClientFromJsonRpc(baseAddress: "http://${relay.ip}:2024/api"))
    .asyncExpand((client) => retryableStream(
        () => RepeatStream((_) => client.adoptions).asyncMap((id) async {
              final header = await client.getBlockHeaderOrRaise(id);
              return SimulationRecord(
                dropletId: relay.id,
                recordTimestamp: Int64(DateTime.now().millisecondsSinceEpoch),
                blockId: id.show,
                timestamp: header.timestamp,
                height: header.height,
                slot: header.slot,
                staker: header.account.show,
              );
            })));
