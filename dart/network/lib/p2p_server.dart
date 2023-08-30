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

  Future<void> stop() async {
    if (_server != null) await _server!.close();
  }
}

class DataGossipSocketHandler {
  final Socket socket;
  final Future<Data?> Function(DataRequest) fulfillRemoteRequest;
  final void Function(DataNotification) dataNotificationReceived;

  final _pendingRequests = <DataRequest, Completer<Data?>>{};

  DataGossipSocketHandler(
      this.socket, this.fulfillRemoteRequest, this.dataNotificationReceived) {
    _processSocket();
  }

  void notifyData(DataNotification notification) {
    final message = Uint8List.fromList([0, notification.typeByte])
      ..addAll(notification.id);
    socket.add(_createSocketFrame(message));
  }

  Future<Data?> requestData(DataRequest request) {
    final message = Uint8List.fromList([1, request.typeByte])
      ..addAll(request.id);
    socket.add(_createSocketFrame(message));
    final completer = Completer<Data?>();
    _pendingRequests[request] = completer;
    return completer.future;
  }

  _createSocketFrame(Uint8List bytes) =>
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
      if (maybeFrame != null) {
        buffer.clear();
        buffer.addAll(maybeFrame.remaining);
        _processFrame(maybeFrame);
        maybeFrame = _parseSocketFrame(buffer);
      }
    });
  }

  void _processFrame(ParsedSocketFrame frame) {
    switch (frame.data[0]) {
      case 0:
        final notification =
            DataNotification(frame.data[1], frame.data.sublist(2));
        dataNotificationReceived(notification);
        break;
      case 1:
        final request = DataRequest(frame.data[1], frame.data.sublist(2));
        fulfillRemoteRequest(request).then((maybeData) {
          if (maybeData != null) {
            final responseMessage = Uint8List.fromList([maybeData.typeByte])
              ..addAll(_intToBytes(maybeData.id.length))
              ..addAll(maybeData.id)
              ..add(1)
              ..addAll(maybeData.data);
            final responseFrame = _createSocketFrame(responseMessage);
            socket.add(responseFrame);
          } else {
            final responseMessage = Uint8List.fromList([request.typeByte])
              ..addAll(request.id)
              ..add(0);
            final responseFrame = _createSocketFrame(responseMessage);
            socket.add(responseFrame);
          }
        });
        break;
      case 3:
        final typeByte = frame.data[1];
        final idLength = _bytesToInt(frame.data.sublist(2, 6));
        final id = frame.data.sublist(6, idLength + 6);
        final hasData = frame.data[idLength + 6] == 1;
        final maybeData = hasData
            ? Data(typeByte, id, frame.data.sublist(idLength + 7))
            : null;
        _pendingRequests[DataRequest(typeByte, id)]?.complete(maybeData);
        break;
    }
  }

  Uint8List _intToBytes(int value) =>
      Uint8List.fromList(Int32(value).toBytes());
  int _bytesToInt(Uint8List bytes) => Int32List.fromList(bytes).first;
}

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
