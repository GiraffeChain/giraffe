import 'dart:io';

import 'package:blockchain/isolate_pool.dart';
import 'package:blockchain_app/widgets/pages/block_page.dart';
import 'package:blockchain_app/widgets/pages/blockchain_launcher_page.dart';
import 'package:blockchain_app/widgets/pages/blockchain_page.dart';
import 'package:blockchain_app/widgets/pages/transaction_page.dart';
import 'package:blockchain_codecs/codecs.dart';
import 'package:blockchain_crypto/kes.dart' as kes;
import 'package:blockchain_crypto/utils.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:blockchain_crypto/ed25519.dart' as ed25519;
import 'package:blockchain_crypto/ed25519vrf.dart' as ed25519VRF;
import 'package:flutter/foundation.dart' show kIsWeb;

var _isolate = LocalCompute;

void main() async {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print(
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
  });
  if (!kIsWeb) {
    final computePool = IsolatePool(Platform.numberOfProcessors);
    _isolate = computePool.isolate;
  }
  ed25519.ed25519 = ed25519.Ed25519Isolated(_isolate);
  ed25519VRF.ed25519Vrf = ed25519VRF.Ed25519VRFIsolated(_isolate);
  kes.kesProduct = kes.KesProudctIsolated(_isolate);

  WidgetsFlutterBinding.ensureInitialized();

  initRouter();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _home(context),
      onGenerateRoute: FluroRouter.appRouter.generator,
    );
  }

  Widget _home(BuildContext context) => Scaffold(
        body: SizedBox.fromSize(
          size: const Size(500, 500),
          child: BlockchainConfigForm(
            onSubmit: (context, config) => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => BlockchainLauncherPage(
                        isolate: _isolate, config: config))),
          ),
        ),
      );
}

initRouter() {
  FluroRouter.appRouter.define("/",
      handler:
          Handler(handlerFunc: (context, params) => const BlockchainPage()));
  FluroRouter.appRouter.define("/blocks/:id",
      handler: Handler(
          handlerFunc: (context, params) =>
              UnloadedBlockPage(id: decodeBlockId(params["id"]![0]))));
  FluroRouter.appRouter.define("/transactions/:id",
      handler: Handler(
          handlerFunc: (context, params) => UnloadedTransactionPage(
              id: decodeTransactionId(params["id"]![0]))));
}
