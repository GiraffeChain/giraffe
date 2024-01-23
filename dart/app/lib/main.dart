import 'dart:io';

import 'package:blockchain/common/isolate_pool.dart';
import 'package:blockchain_app/widgets/pages/block_page.dart';
import 'package:blockchain_app/widgets/pages/blockchain_launcher_page.dart';
import 'package:blockchain_app/widgets/pages/blockchain_page.dart';
import 'package:blockchain_app/widgets/pages/transaction_page.dart';
import 'package:blockchain/codecs.dart';
import 'package:blockchain/crypto/utils.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

var _isolate = LocalCompute;

void main() async {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print(
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
  });
  if (!kIsWeb) {
    final computePool = IsolatePool(Platform.numberOfProcessors);
    _isolate = computePool.isolate;
  }
  setComputeFunction(_isolate);

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
      theme: ThemeData.from(
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.brown, brightness: Brightness.dark)),
    );
  }

  Widget _home(BuildContext context) => Scaffold(
        body: Center(
          child: SizedBox.fromSize(
            size: const Size(500, 500),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: BlockchainConfigForm(
                  onSubmit: (context, config) => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              BlockchainLauncherPage(config: config))),
                ),
              ),
            ),
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
