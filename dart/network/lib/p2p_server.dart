import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

class P2PServer {
  final Uint8List p2pId;
  final String bindHost;
  final int bindPort;
  final Stream<String> knownPeers;
  final void Function(Socket) handleSocket;
  late ServerSocket? _server;

  P2PServer(
    this.p2pId,
    this.bindHost,
    this.bindPort,
    this.knownPeers,
    this.handleSocket,
  );

  Future<void> start() async {
    _server = await ServerSocket.bind(bindHost, bindPort);
    _server!.listen(handleSocket);
    knownPeers.asyncMap((address) async {
      final args = address.split(":");
      final socket = await Socket.connect(args[0], int.parse(args[1]));
      handleSocket(socket);
    }).drain();
  }

  Future<void> cleanup() async {
    if (_server != null) await _server!.close();
  }
}

/**
 * A wrapper around a function which handles a frame (a sequence of bytes).
 * Once handled, the function returns an optional new FrameReceivedHandler to
 * process the next message.  If null, the original handler will be used.
 */
class FrameReceivedHandler {
  final FrameReceivedHandler? Function(Uint8List) handler;

  FrameReceivedHandler(this.handler);

  static final unhandled = FrameReceivedHandler((_) => null);
}

class FramedSocketProcessor {
  final Socket socket;
  FrameReceivedHandler onFrameReceived;

  FramedSocketProcessor({required this.socket, required this.onFrameReceived}) {
    _processSocket();
  }

  void send(List<int> data) {
    final frame = _createSocketFrame(Uint8List.fromList(data));
    socket.add(frame);
  }

  Uint8List _createSocketFrame(Uint8List bytes) =>
      _intToBytes(bytes.length)..addAll(bytes);

  ParsedSocketFrame? _parseSocketFrame(Uint8List buffer) {
    if (buffer.length >= 4) {
      final length = _bytesToInt(buffer.sublist(0, 4));
      if (buffer.length >= (4 + length)) {
        return ParsedSocketFrame(buffer.sublist(4, buffer.length + 4),
            buffer.sublist(buffer.length + 4));
      }
    }
    return null;
  }

  void _processSocket() {
    var buffer = Uint8List.fromList([]);
    socket.forEach((data) {
      buffer.addAll(data);
      var maybeFrame = _parseSocketFrame(buffer);
      while (maybeFrame != null) {
        buffer.clear();
        buffer.addAll(maybeFrame.remaining);
        final newHandler = onFrameReceived.handler(maybeFrame.data);
        onFrameReceived = newHandler ?? onFrameReceived;
        maybeFrame = _parseSocketFrame(buffer);
      }
    });
  }
}

class DataGossipSocketHandler {
  final FramedSocketProcessor processor;
  final Future<Data?> Function(DataRequest) fulfillRemoteRequest;
  final void Function(DataNotification) dataNotificationReceived;

  final _pendingRequests = <DataRequest, Completer<Data?>>{};

  DataGossipSocketHandler(this.processor, this.fulfillRemoteRequest,
      this.dataNotificationReceived) {
    processor.onFrameReceived = FrameReceivedHandler((data) {
      _processFrame(data);
      return null;
    });
  }

  void notifyData(DataNotification notification) {
    final message = Uint8List.fromList([0, notification.typeByte])
      ..addAll(notification.id);
    processor.send(message);
  }

  Future<Data?> requestData(DataRequest request) {
    final message = Uint8List.fromList([1, request.typeByte])
      ..addAll(request.id);
    processor.send(message);
    final completer = Completer<Data?>();
    _pendingRequests[request] = completer;
    return completer.future;
  }

  void _processFrame(Uint8List data) {
    switch (data[0]) {
      case 0:
        final notification = DataNotification(data[1], data.sublist(2));
        dataNotificationReceived(notification);
        break;
      case 1:
        final request = DataRequest(data[1], data.sublist(2));
        fulfillRemoteRequest(request).then((maybeData) {
          if (maybeData != null) {
            final responseMessage = Uint8List.fromList([maybeData.typeByte])
              ..addAll(_intToBytes(maybeData.id.length))
              ..addAll(maybeData.id)
              ..add(1)
              ..addAll(maybeData.data);
            processor.send(responseMessage);
          } else {
            final responseMessage = Uint8List.fromList([request.typeByte])
              ..addAll(request.id)
              ..add(0);
            processor.send(responseMessage);
          }
        });
        break;
      case 3:
        final typeByte = data[1];
        final idLength = _bytesToInt(data.sublist(2, 6));
        final id = data.sublist(6, idLength + 6);
        final hasData = data[idLength + 6] == 1;
        final maybeData =
            hasData ? Data(typeByte, id, data.sublist(idLength + 7)) : null;
        _pendingRequests[DataRequest(typeByte, id)]?.complete(maybeData);
        break;
    }
  }
}

Uint8List _intToBytes(int value) => Uint8List.fromList(Int32(value).toBytes());
int _bytesToInt(Uint8List bytes) => Int32List.fromList(bytes).first;

class ParsedSocketFrame {
  final Uint8List data;
  final Uint8List remaining;

  ParsedSocketFrame(this.data, this.remaining);
}

class DataRequest {
  final int typeByte;
  final Uint8List id;

  DataRequest(this.typeByte, this.id);
}

class DataNotification {
  final int typeByte;
  final Uint8List id;

  DataNotification(this.typeByte, this.id);
}

class DataResponse {
  final int typeByte;
  final Uint8List id;
  final Uint8List? data;

  DataResponse(this.typeByte, this.id, this.data);
}

class Data {
  final int typeByte;
  final Uint8List id;
  final Uint8List data;

  Data(this.typeByte, this.id, this.data);
}
