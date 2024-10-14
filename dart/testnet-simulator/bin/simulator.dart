import 'dart:io';

import 'package:args/args.dart';
import 'package:giraffe_protocol/protocol.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:giraffe_testnet_simulator/simulator.dart';
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
  final walletCount = int.parse(parsedArgs.option("wallets")!);
  final tps = double.parse(parsedArgs.option("tps")!);
  final duration =
      Duration(milliseconds: int.parse(parsedArgs.option("duration-ms")!));
  final digitalOceanToken = Platform.environment["DIGITAL_OCEAN_TOKEN"];
  if (digitalOceanToken == null) {
    throw ArgumentError(
        "DIGITAL_OCEAN_TOKEN environment variable is required.");
  }
  final simulator = Simulator(
    stakerCount: stakerCount,
    relayCount: relayCount,
    duration: duration,
    walletCount: walletCount,
    tps: tps,
    digitalOceanToken: digitalOceanToken,
  );
  await simulator.run();
}

ArgParser get argParser {
  final parser = ArgParser();
  parser.addOption("stakers",
      help: "The number of staker VMs to launch.", defaultsTo: "1");
  parser.addOption("relays",
      help: "The number of relay VMs to launch.", defaultsTo: "1");
  parser.addOption("duration-ms",
      help: "The duration of the simulation in milliseconds.",
      defaultsTo: "600000");
  parser.addOption("wallets",
      help: "Number of wallets/users to simulate.", defaultsTo: "100");
  parser.addOption("tps",
      help: "Approximate transactions-per-second to generate.",
      defaultsTo: "1");
  return parser;
}
