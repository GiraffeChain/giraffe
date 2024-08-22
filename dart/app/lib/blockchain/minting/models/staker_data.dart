import 'package:blockchain_protobuf/models/core.pb.dart';

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
