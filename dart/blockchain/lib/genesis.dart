import 'package:blockchain_protobuf/models/block.pb.dart';
import 'package:blockchain_protobuf/models/transaction.pb.dart';
import 'package:fixnum/fixnum.dart';

FullBlock genesis(Int64 timestamp, List<Transaction> transactions) =>
    FullBlock()
      ..timestamp = timestamp
      ..height = Int64(1)
      ..slot = Int64(0)
      ..parentHeaderId = BlockId(bytes: List.filled(32, -1))
      ..transactions.addAll(transactions);
