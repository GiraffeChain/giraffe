import 'package:blockchain_protobuf/models/block.pb.dart';
import 'package:blockchain_protobuf/models/transaction.pb.dart';
import 'package:fixnum/fixnum.dart';

Block genesis(Int64 timestamp, List<TransactionId> transactionIds) => Block()
  ..timestamp = timestamp
  ..height = Int64(1)
  ..slot = Int64(0)
  ..parentHeaderId = BlockId(bytes: List.filled(32, -1))
  ..transactionIds.addAll(transactionIds);
