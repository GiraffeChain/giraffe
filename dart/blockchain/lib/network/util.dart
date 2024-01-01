import 'dart:typed_data';

typedef PeerId = Uint8List;

typedef BytesReader = Future<List<int>> Function(int);
typedef BytesWriter = Future<void> Function(List<int>);

Uint8List uintToBytes(int value) {
  assert(value >= 0);
  final l = Uint32List(1);
  l[0] = value;
  return l.buffer.asUint8List();
}

int bytesToUint(Uint8List bytes) => bytes.buffer.asUint32List().first;
