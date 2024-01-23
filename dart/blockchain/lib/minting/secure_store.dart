import 'dart:io';
import 'dart:typed_data';

import 'package:mutex/mutex.dart';

abstract class SecureStore {
  Future<void> write(List<int> bytes);
  Future<List<int>?> get consume;
  Future<void> get erase;
}

class DiskSecureStore extends SecureStore {
  final File file;
  final Mutex _m = Mutex();

  DiskSecureStore({required this.file});

  @override
  Future<List<int>?> get consume => _m.protect(() => _consumeImpl);

  @override
  Future<void> get erase => _m.protect(() => _eraseImpl);

  @override
  Future<void> write(List<int> bytes) => _m.protect(() => _writeImpl(bytes));

  Future<void> get _eraseImpl async {
    if (await file.exists()) await _eraseImplNoCheck;
  }

  Future<void> get _eraseImplNoCheck async {
    final stat = await file.stat();
    final size = stat.size;
    await file.writeAsBytes(List.filled(size, 0),
        mode: FileMode.writeOnly, flush: true);
    await file.delete();
  }

  Future<void> _writeImpl(List<int> data) async {
    await _eraseImpl;
    await file.writeAsBytes(data, mode: FileMode.writeOnly, flush: true);
    for (int i = 0; i < data.length; i++) data[i] = 0;
  }

  Future<Uint8List?> get _consumeImpl async {
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      await _eraseImplNoCheck;
      return bytes;
    }
    return null;
  }
}
