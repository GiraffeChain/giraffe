import 'dart:async';
import 'dart:io';

import 'package:blockchain/blockchain.dart';
import 'package:blockchain/config.dart';
import 'package:blockchain/crypto/utils.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:provider/provider.dart';

class BlockchainLauncherPage extends StatefulWidget {
  final DComputeImpl isolate;
  final BlockchainConfig config;

  const BlockchainLauncherPage(
      {super.key, required this.isolate, required this.config});

  @override
  BlockchainLauncherPageState createState() => BlockchainLauncherPageState();
}

class BlockchainLauncherPageState extends State<BlockchainLauncherPage> {
  Future<Blockchain> launch() async {
    await _flutterBackgroundInit();
    final blockchain = await Blockchain.init(widget.config, widget.isolate);
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
              providers: [
                  Provider(
                    create: (_) => snapshot.data!,
                    dispose: (_, blockchain) => blockchain.cleanup(),
                  )
                ],
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

class BlockchainConfigForm extends StatefulWidget {
  const BlockchainConfigForm({super.key, required this.onSubmit});
  final void Function(BuildContext, BlockchainConfig) onSubmit;

  @override
  State<StatefulWidget> createState() => BlockchainConfigFormState();
}

class BlockchainConfigFormState extends State<BlockchainConfigForm> {
  String? p2pBindHost;
  String? p2pBindPort;
  String? p2pKnownPeers;
  @override
  Widget build(BuildContext context) => Column(
        children: [
          TextField(
            onChanged: (v) => p2pBindHost = v,
            decoration:
                const InputDecoration(hintText: "P2P Bind Host. i.e. 0.0.0.0"),
          ),
          TextField(
            onChanged: (v) => p2pBindPort = v,
            decoration:
                const InputDecoration(hintText: "P2P Bind Port. i.e. 2023"),
          ),
          TextField(
            onChanged: (v) => p2pKnownPeers = v,
            decoration: const InputDecoration(
                hintText: "P2P Known Peers. i.e. 1.2.3.4:2023,5.6.7.8:1993"),
          ),
          IconButton(
              onPressed: () => _submit(context), icon: const Icon(Icons.send))
        ],
      );

  _submit(BuildContext context) {
    final config = BlockchainConfig(
        p2p: BlockchainP2P(
      bindHost: p2pBindHost,
      bindPort: p2pBindPort != null ? int.parse(p2pBindPort!) : null,
      knownPeers: p2pKnownPeers?.split(','),
    ));
    widget.onSubmit(context, config);
  }
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
