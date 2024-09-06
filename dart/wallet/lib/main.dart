import 'dart:io';

import '../blockchain/common/isolate_pool.dart';
import 'widgets/pages/block_page.dart';
import 'widgets/pages/blockchain_launcher_page.dart';
import 'widgets/pages/blockchain_page.dart';
import 'widgets/pages/transaction_page.dart';
import 'package:giraffe_sdk/sdk.dart';
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

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SettingsPage(),
      onGenerateRoute: FluroRouter.appRouter.generator,
      theme: ThemeData.from(
          colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.brown,
        brightness: Brightness.light,
        surface: Colors.brown[100],
      )),
    );
  }
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
