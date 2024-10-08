import 'dart:io';

import 'package:async/async.dart';
import 'package:rxdart/streams.dart';
import '../blockchain.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:logging/logging.dart';

import 'peer_handler.dart';
import 'shared_sync.dart';

class P2PNetwork {
  final Map<PeerId, PeerState> connectedPeers;
  final Map<PeerAddress, PeerId?> disconnectedPeers;
  final Handshaker handshaker;
  final BlockchainCore core;
  final PeerId peerId;
  final SharedSync sharedSync;

  P2PNetwork({
    required this.connectedPeers,
    required this.disconnectedPeers,
    required this.handshaker,
    required this.core,
    required this.peerId,
  }) : sharedSync = SharedSync(
            core: core,
            clientsF: () => Map.fromEntries(connectedPeers.entries
                .map((e) => MapEntry(e.key, e.value.interface))));

  factory P2PNetwork.fromKnownPeers({
    required Handshaker handshaker,
    required List<PeerAddress> knownPeers,
    required BlockchainCore core,
    required PeerId peerId,
  }) {
    final disconnectedPeers = knownPeers
        .fold<Map<PeerAddress, PeerId?>>({}, (acc, peer) => acc..[peer] = null);
    return P2PNetwork(
      connectedPeers: {},
      disconnectedPeers: disconnectedPeers,
      handshaker: handshaker,
      core: core,
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
          await handshaker.shakeHands(reader.readBytesExact, socket.add);
      log.info("Connected to peerId=${peerId.show} at address=$address");
      final readerWriter =
          MultiplexedReaderWriter.forChunkedReader(reader, socket.add);
      final ports = await MultiplexerPorts.create(
          readerWriter, () async => currentState, core);
      final interface = PeerBlockchainInterfaceImpl(core: core, ports: ports);
      final peerState = PeerState(
        peerId: peerId,
        publicState: PublicP2PState(localPeer: ConnectedPeer(peerId: peerId)),
        outboundAddress: address,
        interface: interface,
      );
      final handler = PeerBlockchainHandler(
        core: core,
        peerState: peerState,
        sharedSync: sharedSync,
      );
      final sub = MergeStream([
        ports.background(readerWriter),
        handler.handle,
      ]).listen((_) {}, cancelOnError: true);
      peerState.onAbort(sub.cancel);
      peerState.onClose(() async {
        log.info("Closing peerId=${peerId.show}");
        connectedPeers.remove(peerId);
        disconnectedPeers[address] = peerId;
        ports.close();
        await reader.cancel();
        socket.destroy();
      });
      sub.onDone(() => peerState.close());
      sub.onError((e, s) {
        log.warning("Error in peerId=${peerId.show}", e, s);
        return peerState.close();
      });
      connectedPeers[peerId] = peerState;
    } else {
      // No more peers to connect to
    }
  }

  Future<void> close() async {
    await Future.wait(
        connectedPeers.values.toList().map((peerState) => peerState.close()));
  }

  PublicP2PState get currentState {
    final peers = connectedPeers.values
        .map((peerState) => peerState.publicState.localPeer)
        .toList();
    return PublicP2PState(
        localPeer: ConnectedPeer(peerId: peerId), peers: peers);
  }

  Stream<void> background() async* {
    while (true) {
      yield null;
      await connectNext();
      await for (final _
          in Stream.periodic(const Duration(seconds: 1)).take(15)) {
        yield null;
      }
    }
  }

  PeerAddress? _selectNext() {
    if (disconnectedPeers.isNotEmpty) {
      final peerAddress = disconnectedPeers.keys.first;
      final peerIdOpt = disconnectedPeers[peerAddress];
      disconnectedPeers.remove(peerAddress);
      if (peerIdOpt != null && connectedPeers.containsKey(peerIdOpt)) {
        return _selectNext();
      }
      return peerAddress;
    } else if (connectedPeers.isNotEmpty) {
      final shuffledConnectedPeerIds = connectedPeers.keys.toList()..shuffle();
      for (final peerId in shuffledConnectedPeerIds) {
        final peerState = connectedPeers[peerId]!;
        final shuffledPeers = peerState.publicState.peers.toList()..shuffle();
        for (final peer in shuffledPeers) {
          if (!connectedPeers.containsKey(peer.peerId)) {
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
  final List<Future<void> Function()> _abort = [];
  final List<Future<void> Function()> _close = [];

  PeerState({
    required this.peerId,
    required this.publicState,
    required this.outboundAddress,
    required this.interface,
  });

  void onAbort(Future<void> Function() f) {
    _abort.add(f);
  }

  void onClose(Future<void> Function() f) {
    _close.add(f);
  }

  Future<void> abort() async {
    for (final f in _abort) {
      await f();
    }
  }

  Future<void> close() async {
    for (final f in _close) {
      await f();
    }
  }
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
