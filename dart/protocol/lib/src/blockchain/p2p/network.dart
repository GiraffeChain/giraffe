import 'dart:io';

import 'package:async/async.dart';
import 'handshake.dart';
import 'peer_interface.dart';
import 'utils.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:logging/logging.dart';

import 'multiplexer.dart';

class P2PNetwork {
  final Map<PeerId, PeerState> _connectedPeers;
  final Map<PeerAddress, PeerId?> _disconnectedPeers;
  final Handshaker _handshaker;
  final BlockId genesisId;
  final PeerId peerId;

  P2PNetwork({
    required Map<PeerId, PeerState> connectedPeers,
    required Map<PeerAddress, PeerId?> disconnectedPeers,
    required Handshaker handshaker,
    required this.genesisId,
    required this.peerId,
  })  : _connectedPeers = connectedPeers,
        _disconnectedPeers = disconnectedPeers,
        _handshaker = handshaker;

  factory P2PNetwork.fromKnownPeers({
    required Handshaker handshaker,
    required List<PeerAddress> knownPeers,
    required BlockId genesisId,
    required PeerId peerId,
  }) {
    final disconnectedPeers = knownPeers
        .fold<Map<PeerAddress, PeerId?>>({}, (acc, peer) => acc..[peer] = null);
    return P2PNetwork(
      connectedPeers: {},
      disconnectedPeers: disconnectedPeers,
      handshaker: handshaker,
      genesisId: genesisId,
      peerId: peerId,
    );
  }

  Future<void> connectNext() async {
    final address = _selectNext();
    if (address != null) {
      log.info("Connecting to address=$address");
      final socket = await Socket.connect(address.host, address.port);
      final reader = ChunkedStreamReader(socket);
      final peerId =
          await _handshaker.shakeHands(reader.readBytesExact, socket.add);
      log.info("Connected to peerId=${peerId.show} at address=$address");
      final readerWriter =
          MultiplexedReaderWriter.forChunkedReader(reader, socket.add);
      final ports = await MultiplexerPorts.create(
          readerWriter, () async => currentState, genesisId);
      final portsSub =
          ports.background(readerWriter).listen((_) {}, cancelOnError: true);
      final interface = PeerBlockchainInterfaceImpl(ports: ports);
      final peerState = PeerState(
        peerId: peerId,
        publicState: PublicP2PState(localPeer: ConnectedPeer(peerId: peerId)),
        outboundAddress: address,
        interface: interface,
        abort: () async {
          portsSub.cancel();
        },
        close: () async {
          log.info("Closing peerId=${peerId.show}");
          _connectedPeers.remove(peerId);
          _disconnectedPeers[address] = peerId;
          ports.close();
          await reader.cancel();
          socket.destroy();
        },
      );
      portsSub.onDone(() => peerState.close());
      portsSub.onError((e, s) {
        log.warning("Error in peerId=${peerId.show}", e, s);
        return peerState.close();
      });
      _connectedPeers[peerId] = peerState;
    } else {
      // No more peers to connect to
    }
  }

  close() async {
    for (final id in _connectedPeers.keys.toList()) {
      final peerState = _connectedPeers[id]!;
      await peerState.close();
    }
  }

  PublicP2PState get currentState {
    final peers = _connectedPeers.values
        .map((peerState) => peerState.publicState.localPeer)
        .toList();
    return PublicP2PState(
        localPeer: ConnectedPeer(peerId: peerId), peers: peers);
  }

  Stream<void> background() async* {
    while (true) {
      yield null;
      await connectNext();
      yield null;
      await Future.delayed(const Duration(seconds: 15));
    }
  }

  PeerAddress? _selectNext() {
    if (_disconnectedPeers.isNotEmpty) {
      final peerAddress = _disconnectedPeers.keys.first;
      final peerIdOpt = _disconnectedPeers[peerAddress];
      _disconnectedPeers.remove(peerAddress);
      if (peerIdOpt != null && _connectedPeers.containsKey(peerIdOpt)) {
        return _selectNext();
      }
      return peerAddress;
    } else if (_connectedPeers.isNotEmpty) {
      final shuffledConnectedPeerIds = _connectedPeers.keys.toList()..shuffle();
      for (final peerId in shuffledConnectedPeerIds) {
        final peerState = _connectedPeers[peerId]!;
        final shuffledPeers = peerState.publicState.peers.toList()..shuffle();
        for (final peer in shuffledPeers) {
          if (!_connectedPeers.containsKey(peer.peerId)) {
            if (peer.hasHost() && peer.hasPort()) {
              return PeerAddress(host: peer.host.value, port: peer.port.value);
            }
          }
        }
      }
    }
    return null;
  }

  static final log = Logger("Network");
}

class PeerState {
  final PeerId peerId;
  PublicP2PState publicState;
  final PeerAddress? outboundAddress;
  final PeerBlockchainInterface interface;
  final Function() abort;
  final Function() close;

  PeerState({
    required this.peerId,
    required this.publicState,
    required this.outboundAddress,
    required this.interface,
    required this.abort,
    required this.close,
  });
}

class PeerAddress {
  final String host;
  final int port;

  PeerAddress({required this.host, required this.port});

  factory PeerAddress.parse(String raw) {
    final parts = raw.split(":");
    if (parts.length != 2) {
      throw Exception("Invalid peer address: $raw");
    }
    return PeerAddress(host: parts[0], port: int.parse(parts[1]));
  }

  @override
  int get hashCode => Object.hash(host, port);

  @override
  operator ==(Object other) {
    if (other is PeerAddress) {
      return host == other.host && port == other.port;
    }
    return false;
  }

  @override
  String toString() {
    return "$host:$port";
  }
}
