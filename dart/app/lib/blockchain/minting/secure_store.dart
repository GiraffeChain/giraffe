abstract class SecureStore {
  Future<void> write(List<int> bytes);
  Future<List<int>?> get consume;
  Future<void> get erase;
}

class SecureStoreFromFunctions extends SecureStore {
  final Future<void> Function(List<int> bytes) writeKey;
  final Future<List<int>?> Function() readKey;
  final Future<void> Function() eraseKey;

  SecureStoreFromFunctions(
      {required this.writeKey, required this.readKey, required this.eraseKey});

  @override
  Future<void> write(List<int> bytes) => writeKey(bytes);

  @override
  Future<List<int>?> get consume => readKey();

  @override
  Future<void> get erase => eraseKey();
}
