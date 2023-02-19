import 'dart:async';

import 'package:blockchain/blockchain.dart';
import 'package:blockchain/blockchain_config.dart';
import 'package:blockchain_app/widgets/block_create_screen.dart';
import 'package:blockchain_app/widgets/block_screen.dart';
import 'package:blockchain_app/widgets/block_tree.dart';
import 'package:blockchain_codecs/codecs.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:flutter/material.dart';

class BlockchainLoaderWidget extends StatefulWidget {
  final BlockchainConfig config;

  const BlockchainLoaderWidget({super.key, required this.config});

  @override
  State<StatefulWidget> createState() => _BlockchainLoaderWidgetState();
}

class _BlockchainLoaderWidgetState extends State<BlockchainLoaderWidget> {
  late final Future<Blockchain> _blockchain;
  late final Future<void> _completion;

  @override
  void initState() {
    super.initState();
    _blockchain = Blockchain.make(widget.config);
    _completion = _blockchain.then((b) => b.run);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: _blockchain,
      builder: (context, snapshot) => snapshot.hasData
          ? BlockchainWidget(blockchain: snapshot.data!)
          : _loading);

  static const _loading = Scaffold(body: Center(child: Text("Loading")));
}

class BlockchainWidget extends StatelessWidget {
  final Blockchain blockchain;

  const BlockchainWidget({super.key, required this.blockchain});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Blockchain")),
        body: _graphView,
        floatingActionButton: _newBlockButton(context),
      );

  _newBlockButton(BuildContext context) => FloatingActionButton(
        child: const Icon(Icons.create_rounded),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (context) => BlockCreateScreen(
                    blockchain: blockchain,
                    onSubmit: (newFullBlock) => blockchain
                        .validateAndSave(newFullBlock)
                        .then((errors) async {
                      if (errors.isEmpty) {
                        await blockchain.assignScore(newFullBlock.id, 1.0);
                      }
                    }),
                  )),
        ),
      );

  Stream<List<Block>> _accumulateBlocksStream(Blockchain blockchain) =>
      blockchain.adoptions
          .asyncMap(blockchain.blockStore.getOrRaise)
          .transform(StreamTransformer.fromBind((inStream) {
        final List<Block> state = [];
        return inStream.map((block) {
          state.add(block);
          return List.of(state);
        });
      }));

  Widget get _listView => StreamBuilder(
        stream:
            _accumulateBlocksStream(blockchain).map((l) => l.reversed.toList()),
        builder: (context, snapshot) => snapshot.hasData
            ? ListView.builder(
                itemBuilder: (context, index) => _tile(snapshot.data![index]),
                itemCount: snapshot.data!.length,
              )
            : const Text("No blocks yet"),
      );

  Widget _tile(Block block) {
    final id = block.id;
    BigInt bigInt = BigInt.zero;
    for (final byte in id.bytes.take(4)) {
      bigInt = (bigInt << 8) | BigInt.from(byte & 0xff);
    }
    final smallInt = bigInt.toInt();
    final color = Color(smallInt);
    return ListTile(
      leading: Icon(
        Icons.square,
        color: color,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(id.show, textAlign: TextAlign.start),
          Text("Height: ${block.height}")
        ],
      ),
    );
  }

  Widget get _graphView => StreamBuilder(
        stream: _accumulateBlocksStream(blockchain),
        builder: (context, snapshot) => snapshot.hasData
            ? BlockTree(
                key: UniqueKey(),
                blockTreeNodes: List.unmodifiable(
                    snapshot.data!.map((block) => BlockTreeNode(
                          block.id,
                          block.parentHeaderId,
                          5,
                          () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => BlockScreen(block: block))),
                        ))))
            : const Text("No blocks yet"),
      );
}
