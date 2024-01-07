import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain/network/util.dart';

extension SocketOps on Socket {
  Resource<ChunkedStreamReader<int>> get chunkedResource => Resource.make(
      () => Future.value(ChunkedStreamReader(this)),
      (chunked) => chunked.cancel());
}

class FramedIO {
  final Socket socket;
  final ChunkedStreamReader<int> chunkedStreamReader;

  FramedIO(this.socket, this.chunkedStreamReader);

  Future<Uint8List?> read() async {
    final rawLengthBytes = await chunkedStreamReader.readBytes(4);
    if (rawLengthBytes.length < 4) return null;
    final lengthBytes = Uint8List.fromList(rawLengthBytes);
    final length = bytesToUint(lengthBytes);
    final chunk = await chunkedStreamReader.readBytes(length);
    if (chunk.length < length) return null;
    return chunk;
  }

  Future<void> write(List<int> data) async {
    socket.add(uintToBytes(data.length));
    socket.add(data);
    await socket.flush().timeout(Duration(seconds: 5));
  }
}

class MultiplexedIO {
  final FramedIO framed;

  MultiplexedIO(this.framed);

  Future<MultiplexedData?> read() async {
    final frame = await framed.read();
    if (frame == null) return null;
    final portBytes = frame.sublist(0, 4);
    final port = bytesToUint(portBytes);
    final data = frame.sublist(4);
    return MultiplexedData(port, data);
  }

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

  Future<MultiplexedDataExchangePacket?> read() async {
    final data = await multiplexer.read();
    if (data == null) return null;
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

class PortQueues<Request, Response> {
  final Queue<Request> requests = Queue();
  final Queue<CancelableCompleter<Response>> responses = Queue();

  Future<void> processRequest(
      Request request, Future<void> Function(Request) subProcessor) async {
    requests.add(request);
    if (requests.length > 1) {
      return;
    }
    while (requests.isNotEmpty) {
      final request = requests.first;
      await subProcessor(request);
      requests.removeFirst();
    }
  }

  void processResponse(Response response, String ifUnexpectedMessage) {
    assert(responses.isNotEmpty, ifUnexpectedMessage);
    final completer = responses.removeFirst();
    if (!completer.operation.isCompleted) completer.complete(response);
  }

  Future<void> cancelAll(Object error) async {
    final rList = responses.toList();
    responses.removeWhere((_) => true);
    rList.forEach((r) => r.completeError(error));
  }
}
