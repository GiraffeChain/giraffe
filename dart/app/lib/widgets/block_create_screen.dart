import 'dart:async';

import 'package:blockchain/blockchain.dart';
import 'package:blockchain_app/blockchain_widget.dart';
import 'package:blockchain_app/widgets/bitmap_editor.dart';
import 'package:blockchain_codecs/codecs.dart';
import 'package:blockchain_consensus/impl/words.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:flutter/material.dart';

class BlockCreateScreen extends StatelessWidget {
  final BlockId? targetHead;
  final Blockchain blockchain;
  final void Function(FullBlock) onSubmit;

  const BlockCreateScreen(
      {super.key,
      this.targetHead,
      required this.blockchain,
      required this.onSubmit});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Create Block")),
        body: FutureBuilder(
          future: (targetHead ?? blockchain.headId)
              .blockHistory(blockchain)
              .take(5)
              .toList(),
          builder: (context, snapshot) => snapshot.hasData
              ? BlockCreateScreenLoaded(
                  blockchain: blockchain,
                  onSubmit: onSubmit,
                  parentBlocks: snapshot.data!,
                )
              : const Text("Loading"),
        ),
      );
}

class BlockCreateScreenLoaded extends StatefulWidget {
  final Blockchain blockchain;
  final void Function(FullBlock) onSubmit;
  final List<Block> parentBlocks;

  const BlockCreateScreenLoaded(
      {super.key,
      required this.blockchain,
      required this.onSubmit,
      required this.parentBlocks});

  @override
  State<StatefulWidget> createState() => _BlockCreateScreenLoadedState2();
}

class _BlockCreateScreenLoadedState2 extends State<BlockCreateScreenLoaded> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          children: [
            Row(
              children: pseudoRandomWords(
                widget.parentBlocks.first.parentHeaderId,
                widget.parentBlocks.first.reward.account,
              ).map((t) => Text(t)).toList(),
            ),
            SizedBox(
              height: 128,
              child: BitMapRender(
                bitMap: widget.parentBlocks.first.height > 1
                    ? decodeBitMap(widget.parentBlocks.first.proof)
                    : emptyBitMap,
                changes: const Stream.empty(),
              ),
            ),
            Row(
              children: pseudoRandomWords(widget.parentBlocks.first.id,
                      widget.blockchain.blockProducer.rewardsAccount)
                  .map((t) => Text(t))
                  .toList(),
            ),
          ],
        ),
        Expanded(
            child: BitmapEditorWithToolbar(
          bitmap: emptyBitMap,
          onSaved: (bitMap) => _onInputSaved(context, bitMap),
        ))
      ],
    );
  }

  _onInputSaved(BuildContext context, BitMap bitmap) {
    final proof = encodeBitMap(bitmap);
    unawaited(
      widget.blockchain.blockProducer
          .produceBlock(widget.parentBlocks.first, proof)
          .then((block) async => FullBlock(
              parentHeaderId: block.parentHeaderId,
              timestamp: block.timestamp,
              height: block.height,
              proof: block.proof,
              transactions: await Stream.fromIterable(block.transactionIds)
                  .asyncMap(widget.blockchain.transactionStore.getOrRaise)
                  .toList(),
              reward: block.reward))
          .then(widget.onSubmit),
    );
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (context) =>
                BlockchainWidget(blockchain: widget.blockchain)),
        (_) => false);
  }
}
