// The original content is temporarily commented out to allow generating a self-contained demo - feel free to uncomment later.

// // The original content is temporarily commented out to allow generating a self-contained demo - feel free to uncomment later.
//
// // import 'dart:io';
// //
// // import 'package:giraffe_frontend/widgets/pages/address_page.dart';
// // import 'package:giraffe_frontend/widgets/pages/social_page.dart';
// // import 'package:giraffe_frontend/widgets/pages/stake_page.dart';
// // import 'package:giraffe_frontend/widgets/pages/transaction_output_page.dart';
// // import 'package:giraffe_frontend/widgets/pages/wallet_page.dart';
// // import 'package:giraffe_protocol/protocol.dart';
// // import 'package:go_router/go_router.dart';
// //
// // import 'widgets/pages/block_page.dart';
// // import 'widgets/pages/blockchain_launcher_page.dart';
// // import 'widgets/pages/blockchain_page.dart';
// // import 'widgets/pages/transaction_page.dart';
// // import 'package:giraffe_sdk/sdk.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // import 'package:logging/logging.dart';
// // import 'package:flutter/foundation.dart' show kIsWeb;
// //
// // import 'widgets/pages/transfer_page.dart';
// //
// // import 'package:giraffe_protocol/src/rust/api/simple.dart';
// // import 'package:giraffe_protocol/src/rust/frb_generated.dart';
// //
// // var _isolate = LocalCompute;
// //
// // void main1() async {
// //   Logger.root.level = Level.INFO;
// //   Logger.root.onRecord.listen((record) {
// //     // ignore: avoid_print
// //     print(
// //         '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}${record.error ?? ""}${record.stackTrace != null ? "\n${record.stackTrace}" : ""}');
// //   });
// //   if (!kIsWeb) {
// //     final computePool = IsolatePool(Platform.numberOfProcessors);
// //     _isolate = computePool.isolate;
// //   }
// //   setComputeFunction(_isolate);
// //
// //   WidgetsFlutterBinding.ensureInitialized();
// //
// //   runApp(const ProviderScope(child: MainApp()));
// // }
// //
// // void main() async {
// //   await RustLib.init();
// //   final app = MaterialApp(
// //     home: Scaffold(
// //       appBar: AppBar(title: const Text('Giraffe')),
// //       body: Center(
// //         child: FutureBuilder(
// //             future: initBlockchain(),
// //             builder: (context, snapshot) => snapshot.hasData
// //                 ? Text("Loaded")
// //                 : const CircularProgressIndicator()),
// //       ),
// //     ),
// //   );
// //   runApp(app);
// // }
// //
// // class MainApp extends StatelessWidget {
// //   const MainApp({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp.router(
// //       routerConfig: _router,
// //       theme: _theme,
// //     );
// //   }
// // }
// //
// // final _theme = ThemeData.from(
// //     colorScheme: ColorScheme.fromSeed(
// //   seedColor: Colors.brown,
// //   brightness: Brightness.light,
// //   error: Colors.red,
// // ));
// //
// // final _router = GoRouter(routes: [
// //   GoRoute(
// //       path: '/', builder: (context, state) => const BlockchainLauncherPage()),
// //   GoRoute(
// //       path: '/blockchain', builder: (context, state) => const BlockchainPage()),
// //   GoRoute(
// //       path: '/blocks/:id',
// //       builder: (context, state) =>
// //           UnloadedBlockPage(id: decodeBlockId(state.pathParameters['id']!))),
// //   GoRoute(
// //       path: '/transactions/:id',
// //       builder: (context, state) => UnloadedTransactionPage(
// //           id: decodeTransactionId(state.pathParameters['id']!))),
// //   GoRoute(
// //       path: '/transactions/:id/:index',
// //       builder: (context, state) => UnloadedTransactionOutputPage(
// //           reference: TransactionOutputReference(
// //               transactionId: decodeTransactionId(state.pathParameters['id']!),
// //               index: int.parse(state.pathParameters['index']!)))),
// //   GoRoute(
// //       path: '/addresses/:address',
// //       builder: (context, state) => UnloadedAddressPage(
// //           address: decodeLockAddress(state.pathParameters['address']!))),
// //   GoRoute(
// //       path: '/wallet',
// //       builder: (context, state) => const StreamedTransactView()),
// //   GoRoute(path: '/social', builder: (context, state) => const SocialView()),
// //   GoRoute(path: '/stake', builder: (context, state) => const StakeView()),
// //   GoRoute(
// //       path: '/transfer/:tx58',
// //       builder: (context, state) =>
// //           TransferPage(transferData: state.pathParameters['tx58']!)),
// // ]);
// //
//
// import 'package:flutter/material.dart';
// import 'package:giraffe_frontend/src/rust/api/simple.dart';
// import 'package:giraffe_frontend/src/rust/frb_generated.dart';
//
// Future<void> main() async {
//   await RustLib.init();
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(title: const Text('flutter_rust_bridge quickstart')),
//         body: Center(
//           child: Text(
//               'Action: Call Rust `greet("Tom")`\nResult: `${greet(name: "Tom")}`'),
//         ),
//       ),
//     );
//   }
// }
//

import 'package:flutter/material.dart';
import 'package:giraffe_frontend/src/rust/api/simple.dart';
import 'package:giraffe_frontend/src/rust/frb_generated.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Giraffe Chain')),
        body: Center(
          child: WasmTest(),
        ),
      ),
    );
  }
}

class WasmTest extends StatefulWidget {
  const WasmTest({super.key});

  @override
  State<WasmTest> createState() => _WasmTestState();
}

class _WasmTestState extends State<WasmTest> {
  String script = defaultScript;
  String input = "50";
  String? result;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: TextField(
            decoration: const InputDecoration(labelText: 'WASM script'),
            maxLines: 80,
            controller: TextEditingController(text: script),
            onChanged: (value) => script = value,
          ),
        ),
        Expanded(
          child: TextField(
            decoration: const InputDecoration(labelText: 'Input'),
            controller: TextEditingController(text: input),
            onChanged: (value) => input = value,
          ),
        ),
        ElevatedButton(
            onPressed: () async {
              final res =
                  await wasmTest(script: script, input: int.parse(input));
              setState(() {
                result = res.toString();
              });
            },
            child: const Text('Run')),
        if (result != null) Text(result!),
      ],
    );
  }
}

const defaultScript = '''
(module
 (type \$0 (func (param i32) (result i32)))
 (memory \$0 0)
 (export "verify" (func \$module/verify))
 (export "memory" (memory \$0))
 (func \$module/verify (param \$0 i32) (result i32)
  local.get \$0
  i32.const 90
  i32.lt_s
  local.get \$0
  i32.const 55
  i32.gt_s
  i32.and
 )
)
''';
