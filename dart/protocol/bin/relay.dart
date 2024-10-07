import 'dart:io';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:fast_base58/fast_base58.dart';
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
  final rawPeers = parsedArgs.multiOption("peer");
  final genesisBytes =
      (await httpClient.get(Uri.parse(parsedArgs.option("genesis")!)))
          .bodyBytes;
  final genesis = FullBlock.fromBuffer(genesisBytes);
  final core = await BlockchainCore.make(genesis);
  assert(rawPeers.isNotEmpty, "Must specify at least one peer");
  final peers = rawPeers.map(PeerAddress.parse).toList();
  final keyPair = await ed25519.generateKeyPair();
  final handshaker =
      Handshaker(magicBytes: Uint8List(32), sk: keyPair.sk, vk: keyPair.vk);
  final network = P2PNetwork.fromKnownPeers(
      knownPeers: peers,
      handshaker: handshaker,
      core: core,
      peerId: PeerId(value: Base58Encode(keyPair.vk)));
  final sub = network.background().listen((_) {}, cancelOnError: true);

  await ProcessSignal.sigint.watch().first;

  await sub.cancel();
  await network.close();
  await core.close();
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
