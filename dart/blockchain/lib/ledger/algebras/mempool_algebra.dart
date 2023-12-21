import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class MempoolAlgebra {
  Future<Set<TransactionId>> read(BlockId currentHead);
  Future<void> add(TransactionId transactionId);
  Future<void> remove(TransactionId transactionId);
}
