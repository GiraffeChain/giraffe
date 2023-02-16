import 'dart:async';

import 'package:blockchain_protobuf/models/transaction.pb.dart';

abstract class Ledger {
  Future<List<String>> validate(Transaction transaction);
  Future<void> apply(Transaction transaction);
  Future<void> remove(Transaction transaction);
}
