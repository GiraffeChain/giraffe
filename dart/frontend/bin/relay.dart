import 'dart:io';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:fast_base58/fast_base58.dart';
import 'package:giraffe_frontend/blockchain/common/isolate_pool.dart';
import 'package:giraffe_frontend/blockchain/p2p/handshake.dart';
import 'package:giraffe_frontend/blockchain/p2p/network.dart';
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
  // final parsedArgs = argParser.parse(args);
  // final rawPeers = parsedArgs.multiOption("peer");
  final rawPeers = ["localhost:2023"];
  final rawGenesisId = "b_6vB1Ea35M7Yu6MuPhAxbsD4Ldkp9K2C4Jyp8h8MWfDd1";
  // final rawGenesisId = parsedArgs.option("genesis")!;
  final genesisId = decodeBlockId(rawGenesisId);
  assert(rawPeers.isNotEmpty, "Must specify at least one peer");
  final peers = rawPeers.map(PeerAddress.parse).toList();
  final keyPair = await ed25519.generateKeyPair();
  final handshaker =
      Handshaker(magicBytes: Uint8List(32), sk: keyPair.sk, vk: keyPair.vk);
  final network = P2PNetwork.fromKnownPeers(
      knownPeers: peers,
      handshaker: handshaker,
      genesisId: genesisId,
      peerId: PeerId(value: Base58Encode(keyPair.vk)));
  network.background().listen((_) {}, cancelOnError: true);
}

final log = Logger("relay");

ArgParser get argParser {
  final parser = ArgParser();
  parser.addMultiOption("peer",
      help:
          "Peer addresses to connect to initially, in the form host:port. Can be specified multiple times.");
  parser.addOption("genesis");
  return parser;
}
