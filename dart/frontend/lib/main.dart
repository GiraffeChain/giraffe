import 'dart:io';

import 'package:giraffe_frontend/widgets/pages/address_page.dart';
import 'package:giraffe_frontend/widgets/pages/social_page.dart';
import 'package:giraffe_frontend/widgets/pages/stake_page.dart';
import 'package:giraffe_frontend/widgets/pages/transaction_output_page.dart';
import 'package:giraffe_frontend/widgets/pages/wallet_page.dart';
import 'package:giraffe_protocol/protocol.dart';
import 'package:go_router/go_router.dart';

import 'widgets/pages/block_page.dart';
import 'widgets/pages/blockchain_launcher_page.dart';
import 'widgets/pages/blockchain_page.dart';
import 'widgets/pages/transaction_page.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'widgets/pages/transfer_page.dart';

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

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      theme: _theme,
    );
  }
}

final _theme = ThemeData.from(
    colorScheme: ColorScheme.fromSeed(
  seedColor: Colors.brown,
  brightness: Brightness.light,
  error: Colors.red,
));

final _router = GoRouter(routes: [
  GoRoute(
      path: '/', builder: (context, state) => const BlockchainLauncherPage()),
  GoRoute(
      path: '/blockchain', builder: (context, state) => const BlockchainPage()),
  GoRoute(
      path: '/blocks/:id',
      builder: (context, state) =>
          UnloadedBlockPage(id: decodeBlockId(state.pathParameters['id']!))),
  GoRoute(
      path: '/transactions/:id',
      builder: (context, state) => UnloadedTransactionPage(
          id: decodeTransactionId(state.pathParameters['id']!))),
  GoRoute(
      path: '/transactions/:id/:index',
      builder: (context, state) => UnloadedTransactionOutputPage(
          reference: TransactionOutputReference(
              transactionId: decodeTransactionId(state.pathParameters['id']!),
              index: int.parse(state.pathParameters['index']!)))),
  GoRoute(
      path: '/addresses/:address',
      builder: (context, state) => UnloadedAddressPage(
          address: decodeLockAddress(state.pathParameters['address']!))),
  GoRoute(
      path: '/wallet',
      builder: (context, state) => const StreamedTransactView()),
  GoRoute(path: '/social', builder: (context, state) => const SocialView()),
  GoRoute(path: '/stake', builder: (context, state) => const StakeView()),
  GoRoute(
      path: '/transfer/:tx58',
      builder: (context, state) =>
          TransferPage(transferData: state.pathParameters['tx58']!)),
]);
