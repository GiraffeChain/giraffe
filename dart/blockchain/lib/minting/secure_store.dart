import 'dart:io';
import 'dart:typed_data';

import 'package:mutex/mutex.dart';
import 'package:path/path.dart';

abstract class SecureStore {
  Future<void> write(String name, List<int> bytes);
  Future<List<int>?> consume(String name);
  Future<List<String>> list();
  Future<void> erase(String name);
}

class InMemorySecureStore extends SecureStore {
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

class DiskSecureStore extends SecureStore {
  final Directory baseDir;
  final Mutex _m = Mutex();

  DiskSecureStore({required this.baseDir});

  @override
  Future<List<int>?> consume(String name) =>
      _m.protect(() => _consumeImpl(name));

  @override
  Future<void> erase(String name) => _m.protect(() => _eraseImpl(name));

  @override
  Future<List<String>> list() {
    return baseDir.list().map((p) => basename(p.path)).toList();
  }

  @override
  Future<void> write(String name, List<int> bytes) =>
      _m.protect(() => _writeImpl(name, bytes));

  File _nameToFile(String name) => File("${baseDir.path}/$name");

  Future<void> _eraseImpl(String name) async {
    final path = _nameToFile(name);
    if (await path.exists()) await _eraseImplNoCheck(path);
  }

  Future<void> _eraseImplNoCheck(File path) async {
    final stat = await path.stat();
    final size = stat.size;
    await path.writeAsBytes(List.filled(size, 0),
        mode: FileMode.writeOnly, flush: true);
    await path.delete();
  }

  Future<void> _writeImpl(String name, List<int> data) async {
    await _eraseImpl(name);
    final path = _nameToFile(name);
    await path.writeAsBytes(data, mode: FileMode.writeOnly, flush: true);
    for (int i = 0; i < data.length; i++) data[i] = 0;
  }

  Future<Uint8List?> _consumeImpl(String name) async {
    final path = _nameToFile(name);
    if (await path.exists()) {
      final bytes = await path.readAsBytes();
      await _eraseImplNoCheck(path);
      return bytes;
    }
    return null;
  }
}
