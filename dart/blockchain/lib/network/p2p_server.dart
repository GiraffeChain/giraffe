import 'dart:async';
import 'dart:io';

import 'package:blockchain/common/resource.dart';
import 'package:logging/logging.dart';

class P2PServer {
  final String bindHost;
  final int bindPort;
  final void Function(Socket) handleSocket;

  final log = Logger("P2P");

  P2PServer(
    this.bindHost,
    this.bindPort,
    this.handleSocket,
  );

  Resource<void> start() => Resource.make(
          () => ServerSocket.bind(bindHost, bindPort),
          (server) => server.close())
      .flatMap((server) => Resource.make(
          () => Future.sync(() => server.listen((socket) {
                log.info(
                    "Inbound connection initializing from ${socket.remoteAddress}");
                handleSocket(socket);
              })),
          (subscription) => subscription.cancel()))
      .map((_) => ());

  Future<void> connectOutbound(String host, int port) async {
    log.info("Outbound connection initializing to $host:$port");
    final socket = await Socket.connect(host, port);
    handleSocket(socket);
  }
}
