import 'package:blockchain/blockchain.dart';
import 'package:blockchain_app/widgets/bitmap_editor.dart';
import 'package:blockchain_app/widgets/create_block_fab.dart';
import 'package:blockchain_codecs/codecs.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:flutter/material.dart';

class BlockViewScreen extends StatelessWidget {
  final Blockchain blockchain;
  final BlockId blockId;

  const BlockViewScreen(
      {super.key, required this.blockchain, required this.blockId});

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: blockId.blockHistory(blockchain).take(5).toList(),
      builder: (context, snapshot) => snapshot.hasData
          ? _loadedScaffold(context, snapshot.data!)
          : _loadingScaffold);

  get _loadingScaffold => Scaffold(
      appBar: AppBar(title: const Text("Loading Block View")),
      body: const Text("Loading"));

  _loadedScaffold(BuildContext context, List<Block> history) => Scaffold(
        appBar: AppBar(title: const Text("View Block")),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  gradient:
                      LinearGradient(colors: [Colors.purple, Colors.orange])),
              child: Column(children: [
                Text(
                  history.first.id.show,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(history.first.height.toString(),
                    style: const TextStyle(fontStyle: FontStyle.italic)),
              ]),
            ),
            history.first.height > 1
                ? Expanded(
                    child:
                        BitMapRender(bitMap: decodeBitMap(history.first.proof)),
                  )
                : const Text("Genesis")
          ],
        ),
        floatingActionButton:
            newBlockFab(context, blockchain, history.first.id),
      );
}
