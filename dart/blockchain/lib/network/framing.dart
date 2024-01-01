import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:blockchain/network/util.dart';

abstract class FramedIO {
  Future<void> close();
  Future<List<int>> read();
  Future<void> write(List<int> data);
}

class SocketBasedFramedIO extends FramedIO {
  final Socket socket;
  final ChunkedStreamReader<int> chunkedStreamReader;

  SocketBasedFramedIO(this.socket, this.chunkedStreamReader);

  factory SocketBasedFramedIO.forSocket(Socket socket) {
    final chunked = ChunkedStreamReader(socket);
    return SocketBasedFramedIO(socket, chunked);
  }

  @override
  Future<void> close() async {
    socket.destroy();
  }

  @override
  Future<List<int>> read() async {
    final lengthBytes =
        Uint8List.fromList(await chunkedStreamReader.readChunk(4));
    final length = bytesToUint(lengthBytes);
    return await chunkedStreamReader.readChunk(length);
  }

  @override
  Future<void> write(List<int> data) async {
    socket.add(uintToBytes(data.length));
    socket.add(data);
  }
}

abstract class MultiplexedIO {
  Future<void> close();
  Future<MultiplexedData> read();
  Future<void> write(MultiplexedData data);
}

class MultiplexedIOForFramedIO extends MultiplexedIO {
  final FramedIO framed;

  MultiplexedIOForFramedIO(this.framed);

  @override
  Future<void> close() => framed.close();

  @override
  Future<MultiplexedData> read() async {
    final frame = Uint8List.fromList(await framed.read());
    final portBytes = frame.sublist(0, 4);
    final port = bytesToUint(portBytes);
    final data = frame.sublist(4);
    return MultiplexedData(port, data);
  }

  @override
  Future<void> write(MultiplexedData data) async {
    final frame = <int>[]
      ..addAll(uintToBytes(data.port))
      ..addAll(data.data);
    await framed.write(frame);
  }
}

class MultiplexedData {
  final int port;
  final List<int> data;

  MultiplexedData(this.port, this.data);
}

class MultiplexedDataExchange {
  final MultiplexedIO multiplexer;

  MultiplexedDataExchange(this.multiplexer);

  Future<void> close() => multiplexer.close();

  Future<MultiplexedDataExchangePacket> read() async {
    final data = await multiplexer.read();
    final isRequest = data.data[0] == 0;
    final tail = data.data.sublist(1);
    return isRequest
        ? MultiplexedDataRequest(data.port, tail)
        : MultiplexedDataResponse(data.port, tail);
  }

  Future<void> write(MultiplexedDataExchangePacket data) async {
    final bytes = <int>[];
    if (data is MultiplexedDataRequest) {
      bytes.add(0);
      bytes.addAll(data.value);
    } else if (data is MultiplexedDataResponse) {
      bytes.add(1);
      bytes.addAll(data.value);
    }
    await multiplexer.write(MultiplexedData(data.port, bytes));
  }
}

abstract class MultiplexedDataExchangePacket {
  final int port;

  MultiplexedDataExchangePacket(this.port);
}

class MultiplexedDataRequest extends MultiplexedDataExchangePacket {
  final List<int> value;

  MultiplexedDataRequest(int port, this.value) : super(port);
}

class MultiplexedDataResponse extends MultiplexedDataExchangePacket {
  final List<int> value;

  MultiplexedDataResponse(int port, this.value) : super(port);
}

class Codec<T> {
  final List<int> Function(T) encode;
  final T Function(List<int>) decode;

  Codec(this.encode, this.decode);
}
