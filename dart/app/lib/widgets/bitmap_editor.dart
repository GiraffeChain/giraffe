import 'dart:async';
import 'dart:typed_data';

import 'package:bit_array/bit_array.dart';
import 'package:flutter/material.dart';

class BitmapEditorWithToolbar extends StatefulWidget {
  final BitMap bitmap;
  final void Function(BitMap) onSaved;

  const BitmapEditorWithToolbar(
      {super.key, required this.bitmap, required this.onSaved});

  @override
  State<StatefulWidget> createState() => _BitmapEditorWithToolbarState();
}

class _BitmapEditorWithToolbarState extends State<BitmapEditorWithToolbar> {
  int brushSize = 1;
  BitMapEditorTool selectedTool = BitMapEditorTool.draw;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BitMapEditorToolbar(
            onBrushSizeSelected: (size) => setState(() {
              brushSize = size;
            }),
            onToolSelected: (tool) => setState(() {
              selectedTool = tool;
            }),
            onSaved: () => widget.onSaved(widget.bitmap),
            toolSize: brushSize,
            selectedTool: selectedTool,
          ),
          Expanded(
            child: BitmapEditor(
              bitmap: widget.bitmap,
              brushSize: brushSize,
              selectedTool: selectedTool,
            ),
          ),
        ],
      );
}

class BitmapEditor extends StatefulWidget {
  const BitmapEditor(
      {super.key,
      required this.bitmap,
      required this.brushSize,
      required this.selectedTool});
  final BitMap bitmap;
  final int brushSize;
  final BitMapEditorTool selectedTool;

  @override
  State<BitmapEditor> createState() => _BitmapEditorState();
}

class _BitmapEditorState extends State<BitmapEditor> {
  late final StreamController<BitMapChange> bitMapChangesController;
  late final int imageSize;

  @override
  void initState() {
    super.initState();
    imageSize = widget.bitmap.length;
    bitMapChangesController = StreamController.broadcast();
  }

  @override
  void dispose() {
    super.dispose();
    bitMapChangesController.close();
  }

  @override
  Widget build(BuildContext context) => _gestureDetector(
        BitMapRender(
          bitMap: widget.bitmap,
          changes: bitMapChangesController.stream,
        ),
        context,
      );

  GestureDetector _gestureDetector(Widget child, BuildContext context) =>
      GestureDetector(
        child: child,
        onPanStart: (details) =>
            _submitOffsetChange(context, details.globalPosition),
        onPanUpdate: (details) =>
            _submitOffsetChange(context, details.globalPosition),
      );

  void _submitOffsetChange(BuildContext context, Offset offset) {
    final adjustedBrushSize = widget.brushSize - 1;
    final rb = (context.findRenderObject() as RenderBox);
    final squareWidth = rb.size.width / imageSize;
    final squareHeight = rb.size.height / imageSize;
    final newPosition = rb.globalToLocal(offset);
    final x = (newPosition.dx / squareWidth).round();
    final y = (newPosition.dy / squareHeight).round();

    for (int x1 = -adjustedBrushSize; x1 <= adjustedBrushSize; x1++) {
      for (int y1 = -adjustedBrushSize; y1 <= adjustedBrushSize; y1++) {
        bitMapChangesController.add(
          BitMapChange(
              x + x1, y + y1, widget.selectedTool == BitMapEditorTool.draw),
        );
      }
    }
  }
}

typedef BitMap = List<BitArray>;

BitMap get emptyBitMap {
  final result = <BitArray>[];
  for (int i = 0; i < 32; i++) {
    result.add(BitArray(32));
  }
  return result;
}

BitMap decodeBitMap(List<int> bytes) {
  final bitArray = BitArray.fromUint8List(Uint8List.fromList(bytes));
  int i = 0;
  final BitMap result = [];
  late BitArray currentRow;
  while (i < bitArray.length) {
    if (i % 32 == 0) {
      currentRow = BitArray(32);
    }
    currentRow[i % 32] = bitArray[i];
    i++;
    if (i % 32 == 0) {
      result.add(currentRow);
    }
  }

  return result;
}

List<int> encodeBitMap(BitMap bitMap) {
  final List<int> result = [];
  for (final row in bitMap) {
    result.addAll(row.byteBuffer.asUint8List());
  }
  return result;
}

class BitMapChange {
  final int x;
  final int y;
  final bool apply;

  BitMapChange(this.x, this.y, this.apply);
}

class BitMapRender extends StatelessWidget {
  final BitMap bitMap;
  final Stream<BitMapChange> changes;

  const BitMapRender(
      {super.key, required this.bitMap, this.changes = const Stream.empty()});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: StreamBuilder(
        stream: changes.distinct().map((c) => bitMap[c.x][c.y] = c.apply),
        builder: (context, snapshot) => Row(
          children: bitMap.map((d) => _column(d)).toList(),
        ),
      ),
    );
  }

  Widget _column(BitArray data) => Expanded(
        child: Column(
          children: [for (int i = 0; i < data.length; i++) _container(data[i])],
        ),
      );
  Widget _container(bool isActive) => Expanded(
      child: Container(color: isActive ? Colors.black : Colors.blueGrey[100]));
}

class BitMapEditorToolbar extends StatelessWidget {
  final void Function(int) onBrushSizeSelected;
  final void Function(BitMapEditorTool) onToolSelected;
  final void Function() onSaved;

  final int toolSize;
  final BitMapEditorTool selectedTool;

  const BitMapEditorToolbar({
    super.key,
    required this.onBrushSizeSelected,
    required this.onToolSelected,
    required this.onSaved,
    required this.toolSize,
    required this.selectedTool,
  });

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    switch (selectedTool) {
      case BitMapEditorTool.draw:
        icon = Icons.remove;
        break;
      case BitMapEditorTool.erase:
        icon = Icons.add;
        break;
    }

    final otherToolIcon = IconButton(
      onPressed: () {
        switch (selectedTool) {
          case BitMapEditorTool.draw:
            onToolSelected(BitMapEditorTool.erase);
            break;
          case BitMapEditorTool.erase:
            onToolSelected(BitMapEditorTool.draw);
            break;
        }
      },
      icon: Icon(icon),
    );

    final slider = Slider(
      min: 1,
      max: 3,
      divisions: 2,
      value: toolSize.toDouble(),
      onChanged: (v) => onBrushSizeSelected(v.round()),
    );

    final saveIcon =
        IconButton(onPressed: onSaved, icon: const Icon(Icons.save));
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        otherToolIcon,
        slider,
        saveIcon,
      ],
    );
  }
}

enum BitMapEditorTool { draw, erase }
