import 'dart:typed_data';

import 'package:blockchain_protobuf/google/protobuf/wrappers.pb.dart';

typedef BytesReader = Future<List<int>> Function(int);
typedef BytesWriter = Future<void> Function(List<int>);

Uint8List uintToBytes(int value) {
  assert(value >= 0);
  final l = Uint32List(1);
  l[0] = value;
  return l.buffer.asUint8List();
}

int bytesToUint(Uint8List bytes) => bytes.buffer.asUint32List().first;

extension NullableStringOps on String? {
  StringValue? get stringValue =>
      (this != null) ? StringValue(value: this!) : null;
}

extension NullableIntOps on int? {
  UInt32Value? get uint32Value =>
      (this != null) ? UInt32Value(value: this!) : null;
}
