import 'package:blockchain_app/blockchain_widget.dart';
import 'package:blockchain_app/widgets/launcher_form.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _configOrBlockchain(context),
    );
  }

  Widget _configOrBlockchain(BuildContext context) => Center(
        child: Column(
          children: [
            Expanded(
              child: LauncherForm(
                onLaunched: (config) => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) =>
                            BlockchainLoaderWidget(config: config))),
              ),
            )
          ],
        ),
      );
}
