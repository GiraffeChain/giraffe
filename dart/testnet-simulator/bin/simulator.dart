import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:fixnum/fixnum.dart';
import 'package:giraffe_protocol/protocol.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/streams.dart';

void main(List<String> args) async {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print(
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}${record.error ?? ""}${record.stackTrace != null ? "\n${record.stackTrace}" : ""}');
  });
  final computePool = IsolatePool(Platform.numberOfProcessors);
  setComputeFunction(computePool.isolate);
  final parsedArgs = argParser.parse(args);
  final stakerCount = int.parse(parsedArgs.option("stakers")!);
  final relayCount = int.parse(parsedArgs.option("relays")!);
  final duration =
      Duration(milliseconds: int.parse(parsedArgs.option("duration-ms")!));
  final digitalOceanToken = Platform.environment["DIGITAL_OCEAN_TOKEN"]!;
  final simulator = Simulator(
    stakerCount: stakerCount,
    relayCount: relayCount,
    duration: duration,
    digitalOceanToken: digitalOceanToken,
  );
  await simulator.run();
}

final log = Logger("simulator");

ArgParser get argParser {
  final parser = ArgParser();
  parser.addOption("stakers",
      help: "The number of staker VMs to launch.", defaultsTo: "1");
  parser.addOption("relays",
      help: "The number of relay VMs to launch.", defaultsTo: "1");
  parser.addOption("duration-ms",
      help: "The duration of the simulation in milliseconds.",
      defaultsTo: "600000");
  return parser;
}

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

abstract class SimulationStatus {
  const SimulationStatus();

  Map<String, dynamic> toJson();
}

class SimulationStatus_Initializing extends SimulationStatus {
  @override
  Map<String, dynamic> toJson() {
    return {
      "status": "initializing",
    };
  }
}

class SimulationStatus_Running extends SimulationStatus {
  final List<SimulationRecord> records;

  const SimulationStatus_Running({required this.records}) : super();

  @override
  Map<String, dynamic> toJson() {
    return {
      "status": "running",
      "records": records.map((r) => r.toJson()).toList(),
    };
  }
}

class SimulationStatus_Completed extends SimulationStatus {
  final List<SimulationRecord> records;

  const SimulationStatus_Completed({required this.records}) : super();
  @override
  Map<String, dynamic> toJson() {
    return {
      "status": "completed",
      "records": records.map((r) => r.toJson()).toList(),
    };
  }
}

class RelayDroplet {
  final String id;
  final String ip;
  final String region;

  RelayDroplet({required this.id, required this.ip, required this.region});

  static Future<RelayDroplet> create(
    String simulationId,
    int index,
    String digitalOceanToken,
    String genesisUrl,
    List<String> peers,
  ) async {
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $digitalOceanToken",
    };
    final launchScript = """#!/bin/bash
ufw allow 2023
ufw allow 2024
docker run -d --restart=always --pull=always --name giraffe-simulation-relay -p 2023:2023 -p 2024:2024 giraffechain/node:dev --genesis $genesisUrl${peers.map((p) => " --peer $p").join("")}
    """;
    final region = randomRegion();
    final bodyJson = {
      "name": "giraffe-simulation-relay-$simulationId-$index",
      "region": region,
      "size": "s-1vcpu-1gb",
      "image": "docker-20-04",
      "user_data": launchScript,
      "tags": [dropletTag],
    };
    final response = await httpClient.post(
        Uri.parse("https://api.digitalocean.com/v2/droplets"),
        headers: headers,
        body: utf8.encode(jsonEncode(bodyJson)));
    final bodyUtf8 = utf8.decode(response.bodyBytes);
    if (response.statusCode != 202) {
      throw StateError(
          "Failed to create relay droplet. status=${response.statusCode} body=${bodyUtf8}");
    }

    final body = jsonDecode(bodyUtf8);
    final id = (body["droplet"]["id"] as int).toString();
    final ip = await dropletIp(digitalOceanToken, id);
    log.info("Created relay container id=$id ip=$ip region=$region");
    return RelayDroplet(id: id, ip: ip, region: region);
  }
}

class StakingDroplet {
  final String id;
  final String ip;

  StakingDroplet({required this.id, required this.ip});

  static Future<StakingDroplet> create(
    String simulationId,
    int index,
    String digitalOceanToken,
    StakingAccount account,
    RelayDroplet relay,
  ) async {
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $digitalOceanToken",
    };
    final apiAddress = "http://${relay.ip}:2024/api";
    final stakerData = account.stakerData.serialized;
    final launchScript = """#!/bin/bash
docker run -d --restart=always --pull=always --name giraffe-simulation-staker giraffechain/staker:dev --api-address $apiAddress --staker-data $stakerData
    """;
    final bodyJson = {
      "name": "giraffe-simulation-staker-$simulationId-$index",
      "region": relay.region,
      "size": "s-1vcpu-1gb",
      "image": "docker-20-04",
      "user_data": launchScript,
      "tags": [dropletTag],
    };
    final response = await httpClient.post(
        Uri.parse("https://api.digitalocean.com/v2/droplets"),
        headers: headers,
        body: utf8.encode(jsonEncode(bodyJson)));
    final bodyUtf8 = utf8.decode(response.bodyBytes);
    if (response.statusCode != 202) {
      throw StateError(
          "Failed to create staker droplet. status=${response.statusCode} body=${bodyUtf8}");
    }
    final body = jsonDecode(bodyUtf8);
    final id = (body["droplet"]["id"] as int).toString();
    final ip = await dropletIp(digitalOceanToken, id);
    log.info(
        "Created staking container id=$id ip=$ip region=${relay.region} relay=${relay.ip}");
    return StakingDroplet(id: id, ip: ip);
  }
}

String randomRegion() => regions[Random().nextInt(regions.length)];
// https://docs.digitalocean.com/platform/regional-availability/#droplets
const regions = [
  // "nyc3",
  // "nyc1",
  // "sfo1",
  "nyc2",
  // "ams2",
  // "sgp1",
  // "lon1",
  "ams3",
  "fra1",
  // "tor1",
  "sfo2",
  // "blr1",
  // "sfo3",
  "syd1"
];

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

Future<String> dropletIp(String digitalOceanToken, String id) =>
    retryableFuture(() async {
      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $digitalOceanToken",
      };
      final response = await httpClient.get(
        Uri.parse("https://api.digitalocean.com/v2/droplets/$id"),
        headers: headers,
      );
      final bodyUtf8 = utf8.decode(response.bodyBytes);
      if (response.statusCode != 200) {
        throw StateError(
            "Failed to get droplet. status=${response.statusCode} body=${bodyUtf8}");
      }
      final body = jsonDecode(bodyUtf8);
      final ips = body["droplet"]["networks"]["v4"] as List<dynamic>;
      if (ips.isEmpty) {
        throw StateError("No public ip found for droplet $id");
      }
      final ip = ips.firstWhere((ip) => ip["type"] == "public")["ip_address"];
      if (ip == null) {
        throw StateError("No public ip found for droplet $id");
      }
      return ip as String;
    }, retries: 60, delay: const Duration(seconds: 3));

Future<void> deleteSimulationDroplets(String digitalOceanToken) async {
  final headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer $digitalOceanToken",
  };
  final response = await httpClient.delete(
    Uri.parse("https://api.digitalocean.com/v2/droplets?tag_name=$dropletTag"),
    headers: headers,
  );
  if (response.statusCode >= 300) {
    throw StateError(
        "Failed to delete droplets. status=${response.statusCode}");
  }
}

const dropletTag = "giraffe-testnet-simulation";

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
                staker: header.account,
              );
            })));

class SimulationRecord {
  final String dropletId;
  final Int64 recordTimestamp;
  final String blockId;
  final Int64 timestamp;
  final Int64 height;
  final Int64 slot;
  final TransactionOutputReference staker;

  SimulationRecord({
    required this.dropletId,
    required this.recordTimestamp,
    required this.blockId,
    required this.timestamp,
    required this.height,
    required this.slot,
    required this.staker,
  });

  Map<String, dynamic> toJson() => {
        "dropletId": dropletId,
        "recordTimestamp": recordTimestamp,
        "blockId": blockId,
        "timestamp": timestamp.toInt(),
        "height": height.toInt(),
        "slot": slot.toInt(),
        "staker": staker.show,
      };
}
