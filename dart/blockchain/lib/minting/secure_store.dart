abstract class SecureStoreAlgebra {
  Future<void> write(String name, List<int> bytes);
  Future<List<int>?> consume(String name);
  Future<List<String>> list();
  Future<void> erase(String name);
}

class InMemorySecureStore extends SecureStoreAlgebra {
  final _store = <String, List<int>>{};
  @override
  Future<List<int>?> consume(String name) async {
    return _store[name];
  }

  @override
  Future<void> erase(String name) async {
    _store.remove(name);
  }

  @override
  Future<List<String>> list() async {
    return _store.keys.toList();
  }

  @override
  Future<void> write(String name, List<int> bytes) async {
    _store[name] = bytes;
  }
}
