import 'dart:async';
import 'dart:io';

import 'package:blockchain/blockchain.dart';
import 'package:blockchain/config.dart';
import 'package:blockchain_crypto/utils.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:provider/provider.dart';

class BlockchainLauncherPage extends StatefulWidget {
  final DComputeImpl isolate;

  const BlockchainLauncherPage({super.key, required this.isolate});

  @override
  BlockchainLauncherPageState createState() => BlockchainLauncherPageState();
}

class BlockchainLauncherPageState extends State<BlockchainLauncherPage> {
  Future<Blockchain> launch() async {
    await _flutterBackgroundInit();
    final blockchain = await Blockchain.init(
        BlockchainConfig(rpc: BlockchainRpc(enable: !kIsWeb)), widget.isolate);
    blockchain.run();
    return blockchain;
  }

  @override
  void dispose() {
    super.dispose();
    unawaited(_flutterBackgroundRelease());
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: launch(),
      builder: (context, snapshot) => snapshot.hasData
          ? MultiProvider(
              providers: [Provider.value(value: snapshot.data!)],
              child: Navigator(
                initialRoute: '/',
                onGenerateRoute: FluroRouter.appRouter.generator,
              ))
          : loading);

  Widget get loading => Scaffold(
      body: Container(
          constraints: const BoxConstraints.expand(),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          )));
}

_flutterBackgroundInit() async {
  if (!kIsWeb && Platform.isAndroid) {
    const androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "Blockchain",
      notificationText: "Blockchain is running in the background.",
      notificationImportance: AndroidNotificationImportance.Default,
      enableWifiLock: true,
    );
    bool success =
        await FlutterBackground.initialize(androidConfig: androidConfig);

    assert(success);
    await FlutterBackground.enableBackgroundExecution();
  }
}

_flutterBackgroundRelease() async {
  if (!kIsWeb && Platform.isAndroid) {
    await FlutterBackground.disableBackgroundExecution();
  }
}
