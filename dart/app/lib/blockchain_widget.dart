import 'dart:async';

import 'package:async/async.dart' show StreamGroup;
import 'package:blockchain/blockchain.dart';
import 'package:blockchain/config.dart';
import 'package:blockchain_app/widgets/block_tree.dart';
import 'package:blockchain_app/widgets/create_block_fab.dart';
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

  @override
  void initState() {
    super.initState();
    _blockchain = Blockchain.make(widget.config).then((b) {
      b.run();
      return b;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _blockchain.then((b) => b.close());
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: _blockchain,
        builder: (context, snapshot) => snapshot.hasData
            ? BlockchainWidget(blockchain: snapshot.data!)
            : _loading,
      );

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
