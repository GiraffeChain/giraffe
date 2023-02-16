
import 'dart:async';

import 'package:blockchain_protobuf/models/block.pb.dart';
import 'package:blockchain_protobuf/models/transaction.pb.dart';

abstract class Ledger {
  FutureOr<List<TransactionId>> unconfirmedTransactions();
  FutureOr<List<String>> validate(Transaction transaction);
  FutureOr<void> append(Transaction transaction);
  FutureOr<void> remove(Transaction transaction);
}