import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:fixnum/fixnum.dart';

abstract class BlockPacker {
  Stream<FullBlockBody> streamed(
    BlockId parentBlockId,
    Int64 height,
    Int64 slot,
  );
}

class BlockPackerForStakerSupportRpc extends BlockPacker {
  final BlockchainClient client;
  BlockPackerForStakerSupportRpc({required this.client});

  @override
  Stream<FullBlockBody> streamed(
      BlockId parentBlockId, Int64 height, Int64 slot) {
    return client.packBlock
        .map((v) => v.transactionIds.map(client.getTransactionOrRaise))
        .asyncMap(Future.wait)
        .map((transactions) => FullBlockBody(transactions: transactions));
  }
}
