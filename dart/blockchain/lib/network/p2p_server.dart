import 'dart:async';
import 'dart:io';

import 'package:blockchain/common/resource.dart';
import 'package:blockchain/network/util.dart';
import 'package:logging/logging.dart';
import 'package:ribs_effect/ribs_effect.dart';

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

  Resource<BackgroundHandler> start() => Resource.make(
          IO.fromFutureF(() => ServerSocket.bind(bindHost, bindPort)),
          (server) => IO.fromFutureF(() => server.close()).voided())
      .flatMap((server) => ResourceUtils.backgroundStream(server.map((socket) {
            log.info("Inbound connection initializing from ${socket.show}");
            _guardedHandler(socket);
          })));

  Future<void> connectOutbound(String host, int port) async {
    log.info("Outbound connection initializing to $host:$port");
    final socket = await Socket.connect(host, port);
    _guardedHandler(socket);
  }

  _guardedHandler(Socket socket) => runZonedGuarded(() => handleSocket(socket),
      (e, trace) => log.warning("Uncaught P2P error", e, trace));
}
