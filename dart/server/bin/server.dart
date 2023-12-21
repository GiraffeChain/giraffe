import 'dart:io';

import 'package:blockchain/blockchain.dart';
import 'package:blockchain/config.dart';
import 'package:blockchain/isolate_pool.dart';
import 'package:blockchain/crypto/ed25519.dart' as ed25519;
import 'package:blockchain/crypto/ed25519vrf.dart' as ed25519VRF;
import 'package:blockchain/crypto/kes.dart' as kes;
import 'package:blockchain/crypto/utils.dart';
import 'package:logging/logging.dart';

DComputeImpl _isolate = LocalCompute;
Future<void> main() async {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print(
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
  });
  final computePool = IsolatePool(Platform.numberOfProcessors);
  _isolate = computePool.isolate;
  ed25519.ed25519 = ed25519.Ed25519Isolated(_isolate);
  ed25519VRF.ed25519Vrf = ed25519VRF.Ed25519VRFIsolated(_isolate);
  kes.kesProduct = kes.KesProudctIsolated(_isolate);
  final BlockchainConfig config = BlockchainConfig();
  final blockchain = await Blockchain.init(config, _isolate);
  blockchain.run();
}
