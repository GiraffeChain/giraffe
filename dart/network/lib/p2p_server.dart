import 'dart:async';
import 'dart:io';

class P2PServer {
  final String bindHost;
  final int bindPort;
  final void Function(Socket) handleSocket;
  late ServerSocket? _server;

  P2PServer(
    this.bindHost,
    this.bindPort,
    this.handleSocket,
  );

  Future<void> start() async {
    _server = await ServerSocket.bind(bindHost, bindPort);
    _server!.listen(handleSocket);
  }

  Future<void> connectOutbound(String host, int port) async {
    final socket = await Socket.connect(host, port);
    handleSocket(socket);
  }

  Future<void> cleanup() async {
    if (_server != null) await _server!.close();
  }
}
