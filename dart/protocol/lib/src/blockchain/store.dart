import 'package:fixnum/fixnum.dart';
import 'package:giraffe_sdk/sdk.dart';

abstract class Store<Key, Value> {
  Future<Value?> get(Key key);
  Future<void> put(Key key, Value value);
  Future<void> remove(Key key);
  Future<bool> contains(Key key);
  Future<Value> getOrRaise(Key key) async {
    final value = await get(key);
    if (value == null) {
      throw Exception('Value not found for key=$key');
    }
    return value;
  }
}

class DataStores {
  final Store<BlockId, (Int64, BlockId)> blockIdTree;
  final Store<int, BlockId> currentEventIds;
  final Store<BlockId, BlockHeader> headers;
  final Store<BlockId, BlockBody> bodies;
  final Store<TransactionId, Transaction> transactions;
  final Store<Int64, BlockId> blockHeightIndex;

  DataStores({
    required this.blockIdTree,
    required this.currentEventIds,
    required this.headers,
    required this.bodies,
    required this.transactions,
    required this.blockHeightIndex,
  });
}
