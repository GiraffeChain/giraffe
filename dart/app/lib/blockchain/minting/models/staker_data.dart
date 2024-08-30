import 'package:blockchain_sdk/sdk.dart';

class StakerData {
  final List<int> vrfSk;
  final List<int> operatorSk;
  final TransactionOutputReference account;

  StakerData({
    required this.vrfSk,
    required this.operatorSk,
    required this.account,
  });
}
