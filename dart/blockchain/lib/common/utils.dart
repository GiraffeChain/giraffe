import 'dart:typed_data';
import 'package:blockchain/common/models/unsigned.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:logging/logging.dart';

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

extension BlockHeaderOps on BlockHeader {
  UnsignedBlockHeader get unsigned => UnsignedBlockHeader(
        parentHeaderId,
        parentSlot,
        txRoot,
        bloomFilter,
        timestamp,
        height,
        slot,
        eligibilityCertificate,
        PartialOperationalCertificate(
            operationalCertificate.parentVK,
            operationalCertificate.parentSignature,
            operationalCertificate.childVK),
        metadata,
        address,
      );
}

extension TransactionOps on Transaction {
  Int64 get inputSum =>
      inputs.fold(Int64.ZERO, (a, input) => a + input.value.quantity);
  Int64 get outputSum =>
      outputs.fold(Int64.ZERO, (a, input) => a + input.value.quantity);
  Int64 get reward => inputSum - outputSum;
}

extension LogOps on Logger {
  T timedInfo<T>(T Function() f, {String Function(Duration)? messageF}) {
    final start = DateTime.now();
    final r = f();
    final duration = DateTime.now().difference(start);
    final message = (messageF != null)
        ? messageF(duration)
        : "Operation took ${duration.inMilliseconds}";
    info(message);
    return r;
  }

  Future<T> timedInfoAsync<T>(Future<T> Function() f,
      {String Function(Duration)? messageF}) async {
    final start = DateTime.now();
    final r = await f();
    final duration = DateTime.now().difference(start);
    final message = (messageF != null)
        ? messageF(duration)
        : "Operation took ${duration.inMilliseconds}";
    info(message);
    return r;
  }
}
