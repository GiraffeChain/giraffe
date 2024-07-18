import 'package:blockchain/blockchain_view.dart';
import 'package:blockchain/rpc/client.dart';
import 'package:blockchain_app/widgets/resource_builder.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_protobuf/services/node_rpc.pbgrpc.dart';
import 'package:blockchain_protobuf/services/staker_support_rpc.pbgrpc.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ribs_effect/ribs_effect.dart';

class BlockchainLauncherPage extends StatefulWidget {
  final LaunchSettings config;

  const BlockchainLauncherPage({super.key, required this.config});

  @override
  BlockchainLauncherPageState createState() => BlockchainLauncherPageState();
}

class BlockchainLauncherPageState extends State<BlockchainLauncherPage> {
  Resource<(BlockchainView, BlockchainWriter)> launch() =>
      RpcClient.makeChannel(
              host: widget.config.rpcHost, port: widget.config.rpcPort)
          .map((channel) => (
                nodeClient: NodeRpcClientWithRetry(channel,
                    delegate: NodeRpcClient(channel), maxTries: 10),
                stakerSupportClient: StakerSupportRpcClientWithRetry(channel,
                    delegate: StakerSupportRpcClient(channel), maxTries: 10)
              ))
          .map((clients) => (
                BlockchainViewFromRpc(nodeClient: clients.nodeClient),
                BlockchainWriter(
                    submitTransaction: (tx) => clients.nodeClient
                        .broadcastTransaction(
                            BroadcastTransactionReq(transaction: tx)),
                    stakerClient: clients.stakerSupportClient),
              ));

  @override
  Widget build(BuildContext context) =>
      ResourceBuilder<(BlockchainView, BlockchainWriter)>(
          resource: launch(),
          builder: (context,
                  AsyncSnapshot<
                          (
                            BlockchainView,
                            BlockchainWriter,
                          )>
                      snapshot) =>
              snapshot.hasData
                  ? MultiProvider(
                      providers: [
                          Provider(create: (_) => snapshot.data!.$1),
                          Provider(create: (_) => snapshot.data!.$2),
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
  final void Function(BuildContext, LaunchSettings) onSubmit;

  @override
  State<StatefulWidget> createState() => BlockchainConfigFormState();
}

class BlockchainConfigFormState extends State<BlockchainConfigForm> {
  String? rpcHost;
  String? rpcPort;
  @override
  Widget build(BuildContext context) => Column(
        children: [
          TextField(
            onChanged: (v) => rpcHost = v,
            decoration:
                const InputDecoration(hintText: "RPC Host. i.e. localhost"),
          ),
          TextField(
            onChanged: (v) => rpcPort = v,
            decoration: const InputDecoration(hintText: "RPC Port. i.e. 2024"),
          ),
          IconButton(
              onPressed: () => _submit(context), icon: const Icon(Icons.send))
        ],
      );

  _submit(BuildContext context) {
    final config = LaunchSettings(
        rpcHost: rpcHost ?? "localhost", rpcPort: _parsedPort ?? 2024);
    widget.onSubmit(context, config);
  }

  int? get _parsedPort => (rpcPort != null) ? int.tryParse(rpcPort!) : null;
}

class LaunchSettings {
  final String rpcHost;
  final int rpcPort;

  LaunchSettings({required this.rpcHost, required this.rpcPort});
}

class BlockchainWriter {
  final Future<void> Function(Transaction) submitTransaction;
  final StakerSupportRpcClient stakerClient;

  BlockchainWriter(
      {required this.submitTransaction, required this.stakerClient});
}
