import 'package:blockchain/ledger/models/transaction_validation_context.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class TransactionSemanticValidationAlgebra {
  Future<List<String>> validate(
      Transaction transaction, TransactionValidationContext context);
}
