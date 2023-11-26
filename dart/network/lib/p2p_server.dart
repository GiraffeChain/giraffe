import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

class P2PServer {
  final String bindHost;
  final int bindPort;
  final void Function(Socket) handleSocket;
  late ServerSocket? _server;

  final log = Logger("P2P");

  P2PServer(
    this.bindHost,
    this.bindPort,
    this.handleSocket,
  );

  Future<void> start() async {
    _server = await ServerSocket.bind(bindHost, bindPort);
    _server!.listen((socket) {
      log.info("Inbound connection initializing from ${socket.remoteAddress}");
      handleSocket(socket);
    });
  }

  Future<void> connectOutbound(String host, int port) async {
    log.info("Outbound connection initializing to $host:$port");
    final socket = await Socket.connect(host, port);
    handleSocket(socket);
  }

  Future<void> cleanup() async {
    if (_server != null) await _server!.close();
  }
}
