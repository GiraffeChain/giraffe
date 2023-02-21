import 'dart:async';

import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_codecs/codecs.dart';
import 'package:fixnum/fixnum.dart';

class BlockProducer {
  final Account rewardsAccount;
  final Future<List<Transaction>> Function(Block parent) packBlock;

  BlockProducer(this.rewardsAccount, this.packBlock);

  Future<Block> produceBlock(Block parent, List<int> proof) async {
    final transactions = await packBlock(parent);
    return Block()
      ..parentHeaderId = parent.id
      ..height = parent.height + 1
      ..proof = proof
      ..timestamp = Int64(DateTime.now().millisecondsSinceEpoch)
      ..transactionIds.addAll(transactions.map((t) => t.id))
      ..reward = TransactionOutput(
        account: rewardsAccount,
        value: null, // TODO: Value
      );
  }
}
