import 'dart:typed_data';

import 'package:fast_base58/fast_base58.dart';
import 'package:fixnum/fixnum.dart';
import 'package:giraffe_sdk/sdk.dart';

class StakerData {
  final List<int> vrfSk;
  final List<int> operatorSk;
  final TransactionOutputReference account;

  StakerData({
    required this.vrfSk,
    required this.operatorSk,
    required this.account,
  });

  String get serialized {
    final bytes = [
      ...vrfSk,
      ...operatorSk,
      ...Base58Decode(account.transactionId.value),
      ...Int32(account.index).toBytesBigEndian(),
    ];
    return Base58Encode(bytes);
  }

  static StakerData deserialize(String serialized) {
    final bytes = Base58Decode(serialized);
    assert(bytes.length == 100);
    final vrfSk = bytes.sublist(0, 32);
    final operatorSk = bytes.sublist(32, 64);
    final transactionId = bytes.sublist(64, 96);
    final index = Int32List.fromList(bytes.sublist(96, 100)).first;
    final account = TransactionOutputReference(
      transactionId: TransactionId(value: Base58Encode(transactionId)),
      index: index,
    );
    return StakerData(
      vrfSk: vrfSk,
      operatorSk: operatorSk,
      account: account,
    );
  }
}
