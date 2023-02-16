import 'package:blockchain/blockchain_config.dart';
import 'package:blockchain_app/blockchain_widget.dart';
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
      body: Center(
        child: Column(
          children: [
            const Text("Blocks:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: BlockchainWidget(
                  config: BlockchainConfig("localhost", 9555, DateTime.now())),
            )
          ],
        ),
      ),
    );
  }
}
