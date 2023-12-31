import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:blockchain/crypto/ed25519.dart';
import 'package:blockchain/network/handshake.dart';
import 'package:fast_base58/fast_base58.dart';
import 'package:logging/logging.dart';

class PeersManager {
  final log = Logger("PeersManager");

  final Ed25519KeyPair localPeerKeyPair;
  final Uint8List magicBytes;

  PeersManager(this.localPeerKeyPair, this.magicBytes);

  Future<void> handleConnection(Socket socket) async {
    log.info("Initializing handshake with ${socket.remoteAddress}");
    final chunkedReader = ChunkedStreamReader(socket);
    final handshakeResult = await handshake(chunkedReader.readBytes,
        (data) async => socket.add(data), localPeerKeyPair, magicBytes);

    log.info("Handshake success with ${Base58Encode(handshakeResult.peerId)}");
  }
}
