import 'dart:convert';

import 'package:blockchain_codecs/codecs.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:flutter/material.dart';

class BlockScreen extends StatelessWidget {
  final Block block;

  const BlockScreen({super.key, required this.block});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Block View")),
        body: Column(
          children: [
            Text(
              block.id.show,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(block.height.toString(),
                style: const TextStyle(fontStyle: FontStyle.italic)),
            Text(utf8.decode(block.proof))
          ],
        ),
      );
}
