import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';

FullBlock genesis(Int64 timestamp, List<Transaction> transactions) =>
    FullBlock()
      ..timestamp = timestamp
      ..height = Int64(1)
      ..parentHeaderId = BlockId(bytes: List.filled(32, -1))
      ..transactions.addAll(transactions);
