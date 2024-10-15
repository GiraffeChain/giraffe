import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:fixnum/fixnum.dart';
import 'package:giraffe_protocol/protocol.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:giraffe_testnet_simulator/droplets.dart';
import 'package:giraffe_testnet_simulator/log.dart';
import 'package:giraffe_testnet_simulator/simulation_record.dart';
import 'package:giraffe_testnet_simulator/transaction_generator.dart';
import 'package:rxdart/rxdart.dart';

import 'simulation_status.dart';

class Simulator {
  final int stakerCount;
  final int relayCount;
  final Duration duration;
  final int walletCount;
  final double tps;
  final String digitalOceanToken;
  SimulationStatus status = SimulationStatus_Initializing();
  List<AdoptionRecord> adoptionRecords = [];
  List<BlockRecord> blockRecords = [];

  Simulator(
      {required this.stakerCount,
      required this.relayCount,
      required this.duration,
      required this.walletCount,
      required this.tps,
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
    log.info("Generating wallets");
    final wallets = await createWallets(walletCount);
    final walletGenesisTransactions = wallets.map((w) => Transaction(
          outputs: [
            TransactionOutput(
              lockAddress: w.defaultLockAddress,
              quantity: Int64(10000000),
            ),
          ],
        ));
    final genesis = GenesisConfig(
      Int64(startTime.millisecondsSinceEpoch),
      [...initializers.map((i) => i.transaction), ...walletGenesisTransactions],
      [0],
      ProtocolSettings.defaultAsMap,
    ).block;
    log.info("Genesis id=${genesis.header.id.show}");
    log.info(
        "Genesis settings ${genesis.header.settings.entries.map((e) => "${e.key}=${e.value}").join(" ")}");
    final server = SimulatorHttpServer(
      genesis: genesis,
      status: () => status,
      adoptions: () => adoptionRecords,
      blocks: () => blockRecords,
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
      final runningStatus = SimulationStatus_Running();
      status = runningStatus;
      final recordsSub = recordsStream(relays).listen(
        (record) {
          log.info(
              "Recording block id=${record.blockId} droplet=${record.dropletId}");
          adoptionRecords.add(record);
        },
        onError: (e, s) {
          log.severe("Error in simulation record stream", e, s);
        },
        onDone: () => log.info("Simulation record stream done"),
      );
      log.info("Running simulation for $duration");
      await Future.delayed(const Duration(seconds: 15));
      final transactionsSub = TransactionGenerator(
              wallets: wallets, clients: relays.map((r) => r.client).toList())
          .run(Duration(milliseconds: 1000 ~/ tps))
          .listen(
            (tx) => log.info("Broadcasted tx id=${tx.id.show}"),
            onError: (e, s) {
              log.severe("Error in simulation record stream", e, s);
            },
            onDone: () => log.info("Simulation record stream done"),
          );
      await Future.delayed(duration);
      await transactionsSub.cancel();
      await recordsSub.cancel();
      blockRecords = await AdoptionRecord.blockRecords(adoptionRecords, relays);
      status = SimulationStatus_Completed();
      log.info(
          "Mission complete. The simulation server will stay alive until manually stopped. View the results at http://$ip:8080/status");
    } finally {
      log.info("Deleting droplets");
      await deleteSimulationDroplets(digitalOceanToken);
      log.info("Droplets deleted.");
    }
  }

  Future<List<Wallet>> createWallets(int count) {
    return Future.wait(List.generate(
        count,
        (_) async =>
            Wallet.withDefaultKeyPair(await ed25519.generateKeyPair())));
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
          () => container.client.canonicalHeadId,
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
        relays[i % relays.length],
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
  final List<AdoptionRecord> Function() adoptions;
  final List<BlockRecord> Function() blocks;

  SimulatorHttpServer(
      {required this.genesis,
      required this.status,
      required this.adoptions,
      required this.blocks});

  Future<void> run() async {
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
    final idStr = genesis.header.id.show;
    await for (final request in server) {
      final response = request.response;
      if (request.uri.path == "/genesis/$idStr.pbuf") {
        response.add(genesis.writeToBuffer());
      } else if (request.uri.path == "/status") {
        response.write(jsonEncode(status().toJson()));
      } else if (request.uri.path == "/adoptions.csv") {
        response.write(adoptionsCsv());
      } else if (request.uri.path == "/blocks.csv") {
        response.write(blocksCsv());
      } else {
        response.statusCode = HttpStatus.notFound;
      }
      await response.close();
    }
  }

  String adoptionsCsv() {
    return [
      "blockId,timestamp,dropletId",
      ...adoptions().map((a) => a.toCsvRow())
    ].join("\n");
  }

  String blocksCsv() {
    return [
      "blockId,parentBlockId,timestamp,height,slot,txCount",
      ...blocks().map((b) => b.toCsvRow())
    ].join("\n");
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

Stream<AdoptionRecord> recordsStream(List<RelayDroplet> relays) =>
    MergeStream(relays.map((r) => relayRecordsStream(r)));

Stream<AdoptionRecord> relayRecordsStream(RelayDroplet relay) =>
    Stream.value(relay.client).asyncExpand((client) =>
        retryableStream(() => RepeatStream((_) => client.adoptions)).map((id) =>
            AdoptionRecord(
                blockId: id,
                timestamp: DateTime.now().millisecondsSinceEpoch,
                dropletId: relay.id)));
