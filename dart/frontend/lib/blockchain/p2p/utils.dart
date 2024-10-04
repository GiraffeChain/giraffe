import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:giraffe_sdk/sdk.dart';

extension ChunkedStreamReaderExactly on ChunkedStreamReader<int> {
  Future<Uint8List?> readBytesOpt(int size) async {
    final c = await readBytes(size);
    if (c.length != size) {
      return null;
    }
    return c;
  }

  Future<Uint8List> readBytesExact(int size) async {
    final c = await readBytes(size);
    if (c.length != size) {
      throw StateError("Expected exactly $size bytes but received ${c.length}");
    }
    return c;
  }
}

extension PeerIdShowOps on PeerId {
  String get show => "p_${value.substring(0, 8)}";
}
