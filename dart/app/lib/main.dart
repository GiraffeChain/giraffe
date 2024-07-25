import 'dart:io';

import 'package:blockchain/common/isolate_pool.dart';
import 'package:blockchain_app/providers/settings.dart';
import 'package:blockchain_app/widgets/pages/block_page.dart';
import 'package:blockchain_app/widgets/pages/blockchain_launcher_page.dart';
import 'package:blockchain_app/widgets/pages/blockchain_page.dart';
import 'package:blockchain_app/widgets/pages/transaction_page.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

var _isolate = LocalCompute;

void main() async {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print(
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}${record.error ?? ""}${record.stackTrace != null ? "\n${record.stackTrace}" : ""}');
  });
  if (!kIsWeb) {
    final computePool = IsolatePool(Platform.numberOfProcessors);
    _isolate = computePool.isolate;
  }
  setComputeFunction(_isolate);

  WidgetsFlutterBinding.ensureInitialized();

  initRouter();

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _home(context, ref),
      onGenerateRoute: FluroRouter.appRouter.generator,
      theme: ThemeData.from(
          colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.brown,
        brightness: Brightness.light,
        surface: Colors.brown[100],
      )),
    );
  }

  Widget _home(BuildContext context, WidgetRef ref) => Scaffold(
        body: Center(
          child: SizedBox.fromSize(
            size: const Size(500, 500),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: BlockchainConfigForm(
                  onSubmit: (context, config) {
                    ref.read(podSettingsProvider.notifier).setRpc(
                        config.rpcHost, config.rpcPort, config.rpcSecure);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Navigator(
                                  initialRoute: '/',
                                  onGenerateRoute:
                                      FluroRouter.appRouter.generator,
                                )));
                  },
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
