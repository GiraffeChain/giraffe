import 'dart:async';

abstract class Store<Key, Value> {
  Future<Value?> get(Key key);
  Future<void> set(Key key, Value value);
  Future<void> delete(Key key);

  Future<Value> getOrRaise(Key key) async {
    final maybe = await get(key);
    return maybe!;
  }
}

class InMemoryStore<Key, Value> extends Store<Key, Value> {
  final Map<Key, Value> _entries = {};
  @override
  Future<void> delete(Key key) async {
    _entries.remove(key);
  }

  @override
  Future<Value?> get(Key key) async {
    return _entries[key];
  }

  @override
  Future<void> set(Key key, Value value) async {
    _entries[key] = value;
  }
}
