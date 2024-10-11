import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:fixnum/fixnum.dart';
import 'package:giraffe_protocol/protocol.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:logging/logging.dart';

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
      help: "The number of staker VMs to launch.", defaultsTo: "2");
  parser.addOption("relays",
      help: "The number of relay VMs to launch.", defaultsTo: "3");
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
    final genesis = GenesisConfig(
      Int64(DateTime.now().millisecondsSinceEpoch),
      initializers.map((i) => i.transaction).toList(),
      [0],
      ProtocolSettings.defaultAsMap,
    ).block;
    log.info("Genesis id=${genesis.header.id.show}");
    final server = SimulatorHttpServer(
      genesis: genesis,
      status: () => status,
    );
    // No await
    server.run();
    final simulationId = "sim${DateTime.now().millisecondsSinceEpoch}";
    log.info("Simulation id=$simulationId");
    final relays = await launchRelays(simulationId, genesis);
    final stakers = await launchStakers(simulationId, initializers, relays);
    log.info("Running simulation for $duration");
    status = SimulationStatus_Running();
    await Future.delayed(duration);
    status = SimulationStatus_Completed(result: {});
    log.info("Mission complete. Deleting droplets.");
    await Future.wait(stakers.map((r) => deleteDroplet(r.id)));
    await Future.wait(relays.map((r) => deleteDroplet(r.id)));
    log.info("Droplets deleted.");
    log.info("The simulation server will stay alive until manually stopped.");
  }

  Future<List<RelayDroplet>> launchRelays(
      String simulationId, FullBlock genesis) async {
    log.info("Launching $relayCount relay droplets");
    final ip = await publicIp();
    log.info("Simulation public ip=$ip");
    final genesisUrl = "http://$ip:8080/genesis/${genesis.header.id.show}.pbuf";
    log.info("Using genesis at $genesisUrl");
    final containers = <RelayDroplet>[];
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
    return containers;
  }

  Future<List<StakingDroplet>> launchStakers(String simulationId,
      List<StakingAccount> initializers, List<RelayDroplet> relays) async {
    log.info("Launching $stakerCount staker droplets");
    final containers = <StakingDroplet>[];
    for (int i = 0; i < initializers.length; i++) {
      final initializer = initializers[i];
      final container = await StakingDroplet.create(
        simulationId,
        i,
        digitalOceanToken,
        initializer,
        relays[Random().nextInt(relays.length)],
      );
      containers.add(container);
    }
    return containers;
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
  @override
  Map<String, dynamic> toJson() {
    return {
      "status": "running",
    };
  }
}

class SimulationStatus_Completed extends SimulationStatus {
  final dynamic result;

  SimulationStatus_Completed({required this.result}) : super();
  @override
  Map<String, dynamic> toJson() {
    return {
      "status": "completed",
      "result": result,
    };
  }
}

class RelayDroplet {
  final String id;
  final String ip;

  RelayDroplet({required this.id, required this.ip});

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
    final launchScript = """
    #!/bin/bash
    ufw allow 2023
    ufw allow 2024
    docker run -d --restart=always --pull=always --name giraffe-simulation-relay -p 2023:2023 -p 2024:2024 giraffechain/node:dev --genesis $genesisUrl${peers.map((p) => " --peer $p").join("")}
    """;
    final region = randomRegion();
    final bodyJson = {
      "name": "giraffe-simulation-relay-$simulationId-$index",
      "region": region,
      "size": "s-1vcpu-1gb",
      "image": "docker-22-04",
      "user_data": launchScript,
    };
    final response = await httpClient.post(
        Uri.parse("https://api.digitalocean.com/v2/droplets"),
        headers: headers,
        body: utf8.encode(jsonEncode(bodyJson)));
    assert(response.statusCode == 202,
        "Failed to create container. status=${response.statusCode}");
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    final id = body["droplet"]["id"];
    final ips = body["droplet"]["networks"]["v4"] as List<dynamic>;
    final ip = ips.firstWhere((ip) => ip["type"] == "public")["ip_address"]!;
    log.info("Created relay container id=$id ip=$ip region=$region");
    return RelayDroplet(id: id, ip: ip);
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
    final launchScript = """
    #!/bin/bash
    docker run -d --restart=always --pull=always --name giraffe-simulation-staker giraffechain/staker:dev --api-address $apiAddress --staker-data $stakerData
    """;
    final region = randomRegion();
    final bodyJson = {
      "name": "giraffe-simulation-staker-$simulationId-$index",
      "region": region,
      "size": "s-1vcpu-1gb",
      "image": "docker-22-04",
      "user_data": launchScript,
    };
    final response = await httpClient.post(
        Uri.parse("https://api.digitalocean.com/v2/droplets"),
        headers: headers,
        body: utf8.encode(jsonEncode(bodyJson)));
    assert(response.statusCode == 202,
        "Failed to create container. status=${response.statusCode}");
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    final id = body["droplet"]["id"];
    final ips = body["droplet"]["networks"]["v4"] as List<dynamic>;
    final ip = ips.firstWhere((ip) => ip["type"] == "public")["ip_address"]!;
    log.info(
        "Created staking container id=$id ip=$ip region=$region relay=${relay.ip}");
    return StakingDroplet(id: id, ip: ip);
  }
}

String randomRegion() => regions[Random().nextInt(regions.length)];
const regions = [
  "nyc",
  "sfo",
  "ams",
  "sgp",
  "lon",
  "fra",
  "tor",
  "blr",
  "syd",
];

Future<String> publicIp() async {
  final response = await httpClient.get(
    Uri.parse("https://checkip.amazonaws.com"),
  );
  assert(response.statusCode < 300,
      "Failed to get public IP. status=${response.statusCode}");
  final payload = utf8.decode(response.bodyBytes);
  final split = payload.split(',');
  return split.last;
}
