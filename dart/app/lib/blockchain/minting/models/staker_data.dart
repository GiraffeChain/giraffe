import '../secure_store.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';

class StakerData {
  final List<int> vrfSk;
  final TransactionOutputReference account;
  final SecureStore secureStore;
  final Int64 activationOperationalPeriod;

  StakerData({
    required this.vrfSk,
    required this.account,
    required this.secureStore,
    required this.activationOperationalPeriod,
  });
}
