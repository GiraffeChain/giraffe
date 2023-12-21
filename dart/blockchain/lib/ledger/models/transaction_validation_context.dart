import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';

class TransactionValidationContext {
  final BlockId parentHeaderId;
  final List<Transaction> prefix;
  final Int64 height;
  final Int64 slot;

  TransactionValidationContext(
    this.parentHeaderId,
    this.prefix,
    this.height,
    this.slot,
  );
}
