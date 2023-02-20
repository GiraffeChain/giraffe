import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart' show StreamGroup;
import 'package:blockchain/blockchain.dart';
import 'package:blockchain/blockchain_config.dart';
import 'package:blockchain_app/widgets/block_screen.dart';
import 'package:blockchain_app/widgets/block_tree.dart';
import 'package:blockchain_app/widgets/create_block_fab.dart';
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
        floatingActionButton: newBlockFab(context, blockchain, null),
      );

  Stream<List<Block>> _accumulateBlocksStream(Blockchain blockchain) =>
      StreamGroup.merge([
        blockchain.headId.blockHistory(blockchain).take(5),
        blockchain.newBlocks.asyncMap(blockchain.blockStore.getOrRaise)
      ]).transform(StreamTransformer.fromBind((inStream) {
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
                blockchain: blockchain,
              )
            : const Text("No blocks yet"),
      );
}
