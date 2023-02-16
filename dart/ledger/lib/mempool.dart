import 'dart:async';

import 'package:blockchain_protobuf/models/transaction.pb.dart';

abstract class Mempool {
  Future<List<TransactionId>> get get;
  Future<void> add(TransactionId id);
  Future<void> remove(TransactionId id);
}
