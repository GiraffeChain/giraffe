abstract class StoreAlgebra<Key, T> {
  Future<T?> get(Key id);
  Future<bool> contains(Key id);
  Future<void> put(Key id, T value);
  Future<void> remove(Key id);

  Future<T> getOrRaise(Key id) async {
    final maybeValue = await get(id);
    ArgumentError.checkNotNull(maybeValue, "id=$id");
    return maybeValue!;
  }
}

class InMemoryStore<Key, Value> extends StoreAlgebra<Key, Value> {
  Map<Key, Value> _entries = {};

  @override
  Future<bool> contains(Key id) => Future.sync(() => _entries.containsKey(id));

  @override
  Future<Value?> get(Key id) => Future.sync(() => _entries[id]);

  @override
  Future<void> put(Key id, Value value) =>
      Future.sync(() => _entries[id] = value);

  @override
  Future<void> remove(Key id) => Future.sync(() => _entries.remove(id));
}
