import 'dart:async';
import 'dart:io';

import 'package:blockchain/blockchain.dart';
import 'package:blockchain/config.dart';
import 'package:blockchain_app/widgets/blockchain_page.dart';
import 'package:blockchain_crypto/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';

class BlockchainLauncherPage extends StatefulWidget {
  final DComputeImpl isolate;

  const BlockchainLauncherPage({super.key, required this.isolate});

  @override
  _BlockchainLauncherPageState createState() => _BlockchainLauncherPageState();
}

class _BlockchainLauncherPageState extends State<BlockchainLauncherPage> {
  Blockchain? blockchain;

  @override
  void initState() {
    super.initState();

    Future<void> launch() async {
      await _flutterBackgroundInit();
      final blockchain = await Blockchain.init(
          BlockchainConfig(rpc: BlockchainRpc(enable: !kIsWeb)),
          widget.isolate);
      blockchain.run();
      setState(() => this.blockchain = blockchain);
      return;
    }

    unawaited(launch());
  }

  @override
  void dispose() {
    super.dispose();
    unawaited(_flutterBackgroundRelease());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: Container(
          constraints: const BoxConstraints.expand(),
          decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("assets/images/fractal2.png"),
                  fit: BoxFit.cover)),
          child: (blockchain != null)
              ? BlockchainPage(blockchain: blockchain!)
              : loading));

  Widget get loading => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
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
