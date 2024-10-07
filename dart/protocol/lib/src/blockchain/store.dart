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

  static DataStores make() {
    return DataStores(
      blockIdTree: InMemoryDataStore(),
      currentEventIds: InMemoryDataStore(),
      headers: InMemoryDataStore(),
      bodies: InMemoryDataStore(),
      transactions: InMemoryDataStore(),
      blockHeightIndex: InMemoryDataStore(),
    );
  }
}

class InMemoryDataStore<Key, Value> extends Store<Key, Value> {
  final Map<Key, Value> _store = {};

  @override
  Future<bool> contains(Key key) async => _store.containsKey(key);

  @override
  Future<Value?> get(Key key) async => _store[key];

  @override
  Future<void> put(Key key, Value value) async => _store[key] = value;

  @override
  Future<void> remove(Key key) async => _store.remove(key);
}

class EventIdGetterSetters {
  final EventIdGetterSetter canonicalHead;
  final EventIdGetterSetter blockHeightTree;

  EventIdGetterSetters(
      {required this.canonicalHead, required this.blockHeightTree});

  static EventIdGetterSetters make(Store<int, BlockId> store) {
    return EventIdGetterSetters(
      canonicalHead: EventIdGetterSetter.forByte(store, canonicalHeadByte),
      blockHeightTree: EventIdGetterSetter.forByte(store, blockHeightTreeByte),
    );
  }

  static const int canonicalHeadByte = 0;
  static const int blockHeightTreeByte = 3;
}

class EventIdGetterSetter {
  final Future<BlockId> Function() get;
  final Future<void> Function(BlockId) set;

  EventIdGetterSetter({required this.get, required this.set});

  static EventIdGetterSetter forByte(Store<int, BlockId> store, int byte) {
    return EventIdGetterSetter(
      get: () => store.getOrRaise(byte),
      set: (value) => store.put(byte, value),
    );
  }
}
