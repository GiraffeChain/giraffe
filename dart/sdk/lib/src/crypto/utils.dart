import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:hashlib/hashlib.dart';

extension IterableEqOps<T> on Iterable<T> {
  bool sameElements(Iterable<T> other) =>
      const IterableEquality().equals(this, other);
}

extension Uint8ListOps on Uint8List {
  Int8List get int8List => Int8List.fromList(this);
}

extension ListIntHashOps on List<int> {
  Uint8List get hash256 => blake2b256.convert(this).bytes;

  Uint8List get hash512 => blake2b512.convert(this).bytes;
}
