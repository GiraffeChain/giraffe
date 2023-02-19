import 'package:blockchain/blockchain_config.dart';
import 'package:flutter/material.dart';

class LauncherForm extends StatefulWidget {
  const LauncherForm({super.key, required this.onLaunched});

  final void Function(BlockchainConfig) onLaunched;

  @override
  State<StatefulWidget> createState() => _LauncherFormState();
}

class _LauncherFormState extends State<LauncherForm> {
  final _configFormKey = GlobalKey<FormState>();
  final _config = BlockchainConfig(
      "localhost", 9555, DateTime.fromMillisecondsSinceEpoch(0), []);

  @override
  Widget build(BuildContext context) {
    final bindHost = TextFormField(
      initialValue: _config.networkBindHost,
      decoration: const InputDecoration(hintText: "Network bind host"),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Enter a hostname';
        }
        return null;
      },
      onChanged: (host) => setState(() => _config.networkBindHost = host),
    );

    final bindPort = TextFormField(
      initialValue: _config.networkBindPort.toString(),
      decoration: const InputDecoration(hintText: "Network bind port"),
      validator: (value) {
        if (value == null || value.isEmpty || int.tryParse(value) == null) {
          return 'Invalid port';
        }
        return null;
      },
      onChanged: (port) =>
          setState(() => _config.networkBindPort = int.parse(port)),
    );

    final initialPeers = TextFormField(
      initialValue:
          _config.initialPeers.isEmpty ? null : _config.initialPeers.join(","),
      decoration:
          const InputDecoration(hintText: "Initial peers (comma-separated)"),
      validator: (value) {},
      onChanged: (peers) =>
          setState(() => _config.initialPeers = peers.split(',')),
    );

    final genesisTimestamp = TextFormField(
      initialValue: _config.genesisTimestamp.millisecondsSinceEpoch.toString(),
      decoration: const InputDecoration(hintText: "Genesis timestamp"),
      validator: (value) {
        if (value != null) {
          if (int.tryParse(value) == null) {
            return "Invalid timestamp";
          }
        }
      },
      onChanged: (timestamp) => setState(() {
        final maybeInt = int.tryParse(timestamp);
        if (maybeInt != null) {
          _config.genesisTimestamp =
              DateTime.fromMillisecondsSinceEpoch(maybeInt);
        }
      }),
    );

    final launchButton = TextButton.icon(
      onPressed: () {
        final form = _configFormKey.currentState!;
        if (form.validate()) {
          form.save();
          setState(() {
            if (_config.genesisTimestamp.millisecondsSinceEpoch == 0) {
              _config.genesisTimestamp = DateTime.now();
            }
            widget.onLaunched(_config);
            print(_config.genesisTimestamp.millisecondsSinceEpoch);
          });
        }
      },
      icon: const Icon(Icons.launch),
      label: const Text("Launch"),
    );

    return Form(
      key: _configFormKey,
      child: Column(
        children: [
          bindHost,
          bindPort,
          initialPeers,
          genesisTimestamp,
          launchButton
        ],
      ),
    );
  }
}
