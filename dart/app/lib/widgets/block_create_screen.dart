import 'dart:async';
import 'dart:convert';

import 'package:blockchain/blockchain.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:flutter/material.dart';

class BlockCreateScreen extends StatelessWidget {
  final Blockchain blockchain;
  final void Function(FullBlock) onSubmit;

  const BlockCreateScreen(
      {super.key, required this.blockchain, required this.onSubmit});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Create Block")),
        body: FutureBuilder(
          future: _prefixBlocks,
          builder: (context, snapshot) => snapshot.hasData
              ? BlockCreateScreenLoaded(
                  blockchain: blockchain,
                  onSubmit: onSubmit,
                  parentBlocks: snapshot.data!)
              : const Text("Loading"),
        ),
      );

  Future<List<Block>> get _prefixBlocks async {
    final currentHead =
        await blockchain.blockStore.getOrRaise(blockchain.headId);
    final blocks = [currentHead];
    while (blocks.first.height > 1 && blocks.length < 5) {
      blocks.insert(
        0,
        await (blockchain.blockStore.getOrRaise(blocks.first.parentHeaderId)),
      );
    }
    return blocks;
  }
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
  State<StatefulWidget> createState() => _BlockCreateScreenLoadedState();
}

class _BlockCreateScreenLoadedState extends State<BlockCreateScreenLoaded> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) => Form(
      key: _formKey,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Prompt ",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _prefix,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          _input(context),
          _submit
        ],
      ));

  String get _prefix {
    final storyPrefix = widget.parentBlocks
        .map((block) => block.proof)
        .map(utf8.decode)
        .join(" ");

    return "...$storyPrefix";
  }

  Widget _input(BuildContext context) => Padding(
        padding: EdgeInsets.all(32.0),
        child: TextFormField(
          maxLines: 4,
          decoration: InputDecoration(hintText: "Continue the story here..."),
          onSaved: (newValue) {
            unawaited(
              widget.blockchain.blockProducer
                  .produceBlock(
                      widget.parentBlocks.last, utf8.encode(newValue!))
                  .then((block) async => FullBlock(
                      parentHeaderId: block.parentHeaderId,
                      timestamp: block.timestamp,
                      height: block.height,
                      proof: block.proof,
                      transactions:
                          await Stream.fromIterable(block.transactionIds)
                              .asyncMap(
                                  widget.blockchain.transactionStore.getOrRaise)
                              .toList(),
                      reward: block.reward))
                  .then(widget.onSubmit),
            );
            Navigator.of(context).pop();
          },
        ),
      );

  Widget get _submit => TextButton.icon(
        onPressed: () {
          final form = _formKey.currentState!;
          if (form.validate()) {
            form.save();
          }
        },
        icon: const Icon(Icons.launch),
        label: const Text("Launch"),
      );
}
