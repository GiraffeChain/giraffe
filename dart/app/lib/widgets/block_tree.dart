import 'dart:async';
import 'dart:convert';

import 'package:blockchain/blockchain.dart';
import 'package:blockchain_app/widgets/block_screen.dart';
import 'package:blockchain_codecs/codecs.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class BlockTree extends StatefulWidget {
  const BlockTree({super.key, required this.blockchain});

  final Blockchain blockchain;

  @override
  State<BlockTree> createState() => _BlockTreeState();
}

class _BlockTreeState extends State<BlockTree> {
  SugiyamaConfiguration builder = SugiyamaConfiguration();

  final _graph = Graph()..isTree = true;
  final Map<BlockId, Block> _renderedBlocks = {};

  @override
  void initState() {
    super.initState();

    builder
      ..nodeSeparation = (15)
      ..levelSeparation = (15)
      ..orientation = SugiyamaConfiguration.ORIENTATION_BOTTOM_TOP;

    unawaited(_preLaunch());
  }

  Future<void> _preLaunch() async {
    final headId = widget.blockchain.headId;
    final headIds = widget.blockchain.headIds;
    final blocksToDisplay = <BlockId>{};

    await headId
        .idHistory(widget.blockchain)
        .take(5)
        .forEach(blocksToDisplay.add);
    await Future.wait(headIds.map((id) => id
        .idHistory(widget.blockchain)
        .takeWhile((id) => !blocksToDisplay.contains(id))
        .take(5)
        .forEach(blocksToDisplay.add)));

    final blocks = await Stream.fromIterable(blocksToDisplay)
        .asyncMap(widget.blockchain.blockStore.getOrRaise)
        .toList();

    setState(() {
      for (final block in blocks) {
        _renderedBlocks[block.id] = block;
      }

      final nodes = <BlockId, Node>{};
      for (final block in blocks) {
        final blockId = block.id;
        final n = Node.Id(blockId);
        nodes[blockId] = n;
        _graph.addNode(n);
      }
      for (final block in blocks) {
        if (nodes.containsKey(block.parentHeaderId)) {
          _graph.addEdge(nodes[block.id]!, nodes[block.parentHeaderId!]!);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) => (_graph.nodeCount() > 0)
      ? InteractiveViewer(
          constrained: false,
          boundaryMargin: const EdgeInsets.all(100),
          minScale: 0.1,
          maxScale: 2.0,
          child: GraphView(
              graph: _graph,
              algorithm: SugiyamaAlgorithm(builder),
              paint: Paint()
                ..color = Colors.green
                ..strokeWidth = 1
                ..style = PaintingStyle.stroke,
              builder: _nodeWidget),
        )
      : const Text("Loading");

  Widget _nodeWidget(Node node) {
    final block = _renderedBlocks[node.key!.value]!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: Colors.blue[100]!, spreadRadius: 1),
        ],
      ),
      child: InkWell(
        onTap: () => _onPressed(context, node.key!.value),
        child: Text(_blockProofText(block)),
      ),
    );
  }

  _onPressed(BuildContext context, BlockId id) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) =>
            BlockScreen(blockchain: widget.blockchain, blockId: id)));
  }

  _blockProofText(Block block) => utf8.decode(block.proof);
}

class BlockTreeNode {
  final BlockId blockId;
  final BlockId? parentblockId;
  final String label;
  final double? score;
  final void Function() onPressed;

  BlockTreeNode(
      this.blockId, this.parentblockId, this.label, this.score, this.onPressed);
}
