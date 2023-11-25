import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:blockchain_network/util.dart';

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
    final length = bytesToInt(lengthBytes);
    return await chunkedStreamReader.readChunk(length);
  }

  @override
  Future<void> write(List<int> data) async {
    socket.add(intToBytes(data.length));
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
    final port = bytesToInt(portBytes);
    final data = frame.sublist(4);
    return MultiplexedData(port, data);
  }

  @override
  Future<void> write(MultiplexedData data) async {
    final frame = <int>[]..addAll(intToBytes(data.port)..addAll(data.data));
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
  final Map<int, Codec<Object>> requestCodecs;
  final Map<int, Codec<Object>> responseCodecs;
  final Map<int, List<MultiplexedDataExchangePacket>> buffer = {};

  MultiplexedDataExchange(
      this.multiplexer, this.requestCodecs, this.responseCodecs);

  Future<void> close() => multiplexer.close();

  Future<MultiplexedDataExchangePacket> read() async {
    final data = await multiplexer.read();
    final isRequest = data.data[0] == 0;
    final tail = data.data.sublist(1);
    final decoded = isRequest
        ? requestCodecs[data.port]!.decode(tail)
        : responseCodecs[data.port]!.decode(tail);
    return isRequest
        ? MultiplexedDataRequest(data.port, decoded)
        : MultiplexedDataResponse(data.port, decoded);
  }

  Future<MultiplexedDataExchangePacket> readPort(int port) async {
    final buffered = buffer[port] ?? [];
    if (buffered.isNotEmpty) {
      buffer[port] = buffered.sublist(1);
      return buffered[0];
    }
    MultiplexedDataExchangePacket next = await read();
    while (next.port != port) {
      final buffered = buffer[next.port] ?? [];
      buffer[next.port] = buffered..add(next);
    }
    return next;
  }

  Future<void> write(MultiplexedDataExchangePacket data) async {
    final bytes = <int>[];
    if (data is MultiplexedDataRequest) {
      bytes.add(0);
      bytes.addAll(requestCodecs[data.port]!.encode(data.value));
    } else if (data is MultiplexedDataResponse) {
      bytes.add(1);
      bytes.addAll(responseCodecs[data.port]!.encode(data.value));
    }
    multiplexer.write(MultiplexedData(data.port, bytes));
  }
}

abstract class MultiplexedDataExchangePacket {
  final int port;

  MultiplexedDataExchangePacket(this.port);
}

class MultiplexedDataRequest<T> extends MultiplexedDataExchangePacket {
  final T value;

  MultiplexedDataRequest(port, this.value) : super(port);
}

class MultiplexedDataResponse<T> extends MultiplexedDataExchangePacket {
  final T value;

  MultiplexedDataResponse(port, this.value) : super(port);
}

class Codec<T> {
  final List<int> Function(T) encode;
  final T Function(List<int>) decode;

  Codec(this.encode, this.decode);
}
