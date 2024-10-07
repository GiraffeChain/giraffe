import 'package:giraffe_sdk/sdk.dart';

export 'clock.dart';
export 'isolate_pool.dart';
export 'models/common.dart';
export 'models/unsigned.dart';

typedef FetchHeader = Future<BlockHeader> Function(BlockId blockId);
typedef FetchBody = Future<BlockBody> Function(BlockId blockId);
typedef FetchTransaction = Future<Transaction> Function(
    TransactionId transactionId);
typedef FetchBlock = Future<Block> Function(BlockId blockId);
