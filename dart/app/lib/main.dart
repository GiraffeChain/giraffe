import 'package:blockchain/blockchain_config.dart';
import 'package:blockchain_app/blockchain_widget.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BlockchainApp());
}

class BlockchainApp extends StatelessWidget {
  const BlockchainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobilechain',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BlockchainHomePage(title: 'Mobilechain'),
    );
  }
}

class BlockchainHomePage extends StatefulWidget {
  const BlockchainHomePage({super.key, required this.title});

  final String title;

  @override
  State<BlockchainHomePage> createState() => _BlockchainHomePageState();
}

class _BlockchainHomePageState extends State<BlockchainHomePage> {
  final _configFormKey = GlobalKey<FormState>();

  final _config = BlockchainConfig(
      "localhost", 9555, DateTime.fromMillisecondsSinceEpoch(0), []);
  bool _launched = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child:
                  _launched ? BlockchainWidget(config: _config) : _configForm,
            )
          ],
        ),
      ),
    );
  }

  Widget get _configForm {
    final bindHost = TextFormField(
      initialValue: _config.networkBindHost,
      decoration: const InputDecoration(hintText: "Network bind host"),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Enter a hostname';
        }
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
          setState(() => _config.initialPeers = peers?.split(',') ?? []),
    );

    final genesisTimestamp = TextFormField(
      initialValue: _config.genesisTimestamp.millisecondsSinceEpoch.toString(),
      decoration: const InputDecoration(hintText: "Genesis timestamp"),
      validator: (value) {
        if (value != null) int.tryParse(value) != null;
      },
      onChanged: (timestamp) => setState(() {
        final maybeInt = int.tryParse(timestamp);
        if (maybeInt != null) {
          _config.genesisTimestamp =
              DateTime.fromMillisecondsSinceEpoch(maybeInt!);
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
            _launched = true;
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
