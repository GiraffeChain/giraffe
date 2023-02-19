import 'package:blockchain_codecs/codecs.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class BlockTree extends StatefulWidget {
  const BlockTree({super.key, required this.blockTreeNodes});

  final List<BlockTreeNode> blockTreeNodes;

  @override
  State<BlockTree> createState() => _BlockTreeState();
}

class _BlockTreeState extends State<BlockTree> {
  SugiyamaConfiguration builder = SugiyamaConfiguration();

  final _graph = Graph()..isTree = true;

  @override
  void initState() {
    super.initState();
    final nodes = <BlockId, Node>{};
    for (final treeNode in widget.blockTreeNodes) {
      final n = Node.Id(treeNode.blockId);
      nodes[treeNode.blockId] = n;
      _graph.addNode(n);
    }
    for (final treeNode in widget.blockTreeNodes) {
      if (treeNode.parentblockId != null &&
          nodes.containsKey(treeNode.parentblockId)) {
        _graph.addEdge(
            nodes[treeNode.blockId]!, nodes[treeNode.parentblockId!]!);
      }
    }

    builder
      ..nodeSeparation = (15)
      ..levelSeparation = (15)
      ..orientation = SugiyamaConfiguration.ORIENTATION_RIGHT_LEFT;
  }

  @override
  Widget build(BuildContext context) => InteractiveViewer(
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
      );

  Widget _nodeWidget(Node node) {
    final blockTreeNode = widget.blockTreeNodes
        .firstWhere((element) => element.blockId == node.key!.value);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: Colors.blue[100]!, spreadRadius: 1),
        ],
      ),
      child: InkWell(
        onTap: () => blockTreeNode.onPressed(),
        child: Text(blockTreeNode.blockId.show),
      ),
    );
  }
}

class BlockTreeNode {
  final BlockId blockId;
  final BlockId? parentblockId;
  final double? score;
  final void Function() onPressed;

  BlockTreeNode(this.blockId, this.parentblockId, this.score, this.onPressed);
}
