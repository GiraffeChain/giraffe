import 'dart:typed_data';
import 'package:fixnum/fixnum.dart';

// Source: https://github.com/dart-lang/sdk/issues/32803#issuecomment-1228291047
extension BigIntOps on BigInt {
  Uint8List get bytes {
    final data = ByteData(bitLength ~/ 8 + 1);
    var _bigInt = this;

    for (var i = data.lengthInBytes - 1; i >= 0; i--) {
      data.setUint8(i, _bigInt.toUnsigned(8).toInt());
      _bigInt = _bigInt >> 8;
    }

    return Uint8List.view(data.buffer);
  }
}

extension Int32Ops on Int32 {
  BigInt get toBigInt => BigInt.from(this.toInt());
}

extension Int64Ops on Int64 {
  BigInt get toBigInt => BigInt.parse(toString());
}

extension ListIntOps on List<int> {
  BigInt get toBigInt {
    final data = Int8List.fromList(this).buffer.asByteData();
    BigInt _bigInt = BigInt.zero;

    for (var i = 0; i < data.lengthInBytes; i++) {
      _bigInt = (_bigInt << 8) | BigInt.from(data.getUint8(i));
    }
    return _bigInt;
  }
}
