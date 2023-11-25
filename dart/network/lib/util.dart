import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

typedef PeerId = Uint8List;

typedef BytesReader = Future<List<int>> Function(int);
typedef BytesWriter = Future<void> Function(List<int>);

Uint8List intToBytes(int value) => Uint8List.fromList(Int32(value).toBytes());
int bytesToInt(Uint8List bytes) => Int32List.fromList(bytes).first;
