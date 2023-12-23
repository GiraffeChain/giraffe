import 'package:blockchain/blockchain_view.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain_app/widgets/resource_builder.dart';
import 'package:blockchain_protobuf/services/node_rpc.pbgrpc.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grpc/grpc.dart';

class BlockchainLauncherPage extends StatefulWidget {
  final LaunchSettings config;

  const BlockchainLauncherPage({super.key, required this.config});

  @override
  BlockchainLauncherPageState createState() => BlockchainLauncherPageState();
}

class BlockchainLauncherPageState extends State<BlockchainLauncherPage> {
  Resource<BlockchainView> launch() =>
      Resource.pure(NodeRpcClient(ClientChannel(widget.config.rpcHost,
              port: widget.config.rpcPort,
              options: const ChannelOptions(
                  credentials: ChannelCredentials.insecure()))))
          .map((client) => BlockchainViewFromRpc(nodeClient: client));

  @override
  Widget build(BuildContext context) => ResourceBuilder<BlockchainView>(
      resource: launch(),
      builder: (context, AsyncSnapshot<BlockchainView> snapshot) =>
          snapshot.hasData
              ? MultiProvider(
                  providers: [
                      Provider(
                        create: (_) => snapshot.data!,
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
