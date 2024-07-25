import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlockchainLauncherPage extends ConsumerWidget {
  final LaunchSettings config;

  const BlockchainLauncherPage({super.key, required this.config});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Navigator(
        initialRoute: '/',
        onGenerateRoute: FluroRouter.appRouter.generator,
      );
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
      rpcHost: rpcHost ?? "localhost",
      rpcPort: _parsedPort ?? 2024,
      rpcSecure: false, // TODO
    );
    widget.onSubmit(context, config);
  }

  int? get _parsedPort => (rpcPort != null) ? int.tryParse(rpcPort!) : null;
}

class LaunchSettings {
  final String rpcHost;
  final int rpcPort;
  final bool rpcSecure;

  LaunchSettings(
      {required this.rpcHost, required this.rpcPort, required this.rpcSecure});
}
