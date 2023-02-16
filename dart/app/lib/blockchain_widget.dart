import 'dart:async';

import 'package:blockchain/blockchain.dart';
import 'package:blockchain/blockchain_config.dart';
import 'package:blockchain_codecs/codecs.dart';
import 'package:blockchain_protobuf/models/block.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

class BlockchainWidget extends StatefulWidget {
  final BlockchainConfig config;

  const BlockchainWidget({super.key, required this.config});

  @override
  State<StatefulWidget> createState() => _BlockchainWidgetState();
}

class _BlockchainWidgetState extends State<BlockchainWidget> {
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
            ? _accumulateBlocksStream(snapshot.data!)
            : const Text("Loading..."),
      );

  _accumulateBlocksStream(Blockchain blockchain) => StreamBuilder(
        stream: blockchain.consensus.adoptions
            .asyncMap(blockchain.blockStore.getOrRaise)
            .transform(StreamTransformer.fromBind((inStream) {
          final List<Block> state = [];
          return inStream.map((block) {
            state.add(block);
            return List.of(state).reversed.toList();
          });
        })),
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
          Text("Height: ${block.height}"),
          Text("Slot: ${block.slot}")
        ],
      ),
    );
  }
}
