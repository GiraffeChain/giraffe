import 'dart:math';
import 'dart:typed_data';

import 'package:bit_array/bit_array.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:flutter/material.dart';

typedef BitMap = List<List<bool>>;

BitMap decodeBitMap(List<int> bytes) {
  final bitArray = BitArray.fromUint8List(Uint8List.fromList(bytes));
  int i = 0;
  final BitMap result = [];
  final dimension = sqrt(bitArray.length).floor();
  List<bool> currentRow = List.filled(dimension, false);
  while (i < bitArray.length) {
    if (i % dimension == 0) {
      currentRow = List.filled(dimension, false);
    }
    currentRow[i % dimension] = bitArray[i];
    i++;
    if (i % dimension == 0) {
      result.add(currentRow);
    }
  }

  return result;
}

class BitMapViewer extends StatelessWidget {
  final BitMap bitMap;
  final Color onColor;
  final Color offColor;

  const BitMapViewer(
      {super.key,
      required this.bitMap,
      required this.onColor,
      required this.offColor});

  static BitMapViewer forBlock(BlockId blockId) => BitMapViewer(
      bitMap: decodeBitMap(blockId.value),
      onColor: Colors.red.shade50,
      offColor: Colors.red.shade900);

  static BitMapViewer forTransaction(TransactionId transactionId) =>
      BitMapViewer(
          bitMap: decodeBitMap(transactionId.value),
          onColor: Colors.blue.shade50,
          offColor: Colors.blue.shade900);

  static BitMapViewer forLockAddress(LockAddress lockAddress) => BitMapViewer(
      bitMap: decodeBitMap(lockAddress.value),
      onColor: Colors.green.shade50,
      offColor: Colors.green.shade900);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: bitMap.map((d) => _column(d)).toList(),
    );
  }

  Widget _column(List<bool> data) => Expanded(
        child: Column(
          children: [for (int i = 0; i < data.length; i++) _container(data[i])],
        ),
      );
  Widget _container(bool isActive) =>
      Expanded(child: Container(color: isActive ? onColor : offColor));
}
