import 'package:blockchain/blockchain.dart';
import 'package:blockchain_app/widgets/block_create_screen.dart';
import 'package:blockchain_codecs/codecs.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:flutter/material.dart';

newBlockFab(BuildContext context, Blockchain blockchain, BlockId? targetHead) =>
    FloatingActionButton(
      child: const Icon(Icons.add_box),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) => BlockCreateScreen(
                  blockchain: blockchain,
                  targetHead: targetHead,
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
