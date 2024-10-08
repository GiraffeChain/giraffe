import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:rational/rational.dart';

import '../blockchain_core.dart';
import 'multiplexer.dart';

abstract class PeerBlockchainInterface {
  Future<PublicP2PState> publicState();
  Future<BlockId> nextBlockAdoption();
  Future<TransactionId> nextTransactionNotification();
  Future<BlockHeader?> fetchHeader(BlockId id);
  Future<BlockBody?> fetchBody(BlockId id);
  Future<Transaction?> fetchTransaction(TransactionId id);
  Future<BlockId?> blockIdAtHeight(Int64 height);
  Future<Uint8List> ping(Uint8List message);
  Future<BlockId> commonAncestor();

  Future<BlockHeader?> fetchHeaderAtHeight(Int64 height) async {
    final blockId = await blockIdAtHeight(height);
    if (blockId == null) return null;
    return fetchHeader(blockId);
  }
}

class PeerBlockchainInterfaceImpl extends PeerBlockchainInterface {
  final BlockchainCore core;
  final MultiplexerPorts ports;

  PeerBlockchainInterfaceImpl({required this.core, required this.ports});

  @override
  Future<BlockId?> blockIdAtHeight(Int64 height) =>
      ports.blockIdAtHeight.request(height).timeout(defaultReadTimeout);

  @override
  Future<BlockId> commonAncestor() async {
    final localHeadId = core.consensus.localChain.head;
    final localHeader = await core.dataStores.headers.getOrRaise(localHeadId);
    Future<BlockId> getLocalBlockIdAtHeight(Int64 height) async {
      final blockId = await core.consensus.localChain.blockIdAtHeight(height);
      if (blockId == null) {
        throw Exception('BlockId not found at height=$height');
      }
      return blockId;
    }

    final r1 = await quickSearch(getLocalBlockIdAtHeight, blockIdAtHeight,
            Int64(5), localHeader.height)
        .timeout(const Duration(seconds: 30));
    if (r1 != null) return r1;
    final r2 = await narySearch(getLocalBlockIdAtHeight, blockIdAtHeight,
            Rational.fromInt(2, 3), Int64(1), localHeader.height)
        .timeout(const Duration(seconds: 30));
    if (r2 == null) {
      throw StateError('Common ancestor not found');
    }
    return r2;
  }

  @override
  Future<BlockBody?> fetchBody(BlockId id) =>
      ports.bodies.request(id).timeout(defaultReadTimeout);

  @override
  Future<BlockHeader?> fetchHeader(BlockId id) =>
      ports.headers.request(id).timeout(defaultReadTimeout);

  @override
  Future<Transaction?> fetchTransaction(TransactionId id) =>
      ports.transactions.request(id).timeout(defaultReadTimeout);

  @override
  Future<BlockId> nextBlockAdoption() => ports.blockAdoptions.request(null);

  @override
  Future<TransactionId> nextTransactionNotification() =>
      ports.transactionAdoptions.request(null);

  @override
  Future<Uint8List> ping(Uint8List message) =>
      ports.pingPong.request(message).timeout(defaultReadTimeout);

  @override
  Future<PublicP2PState> publicState() =>
      ports.p2pState.request(null).timeout(defaultReadTimeout);
}

const defaultReadTimeout = Duration(seconds: 5);

Future<T?> quickSearch<T>(Future<T> Function(Int64) getLocal,
    Future<T?> Function(Int64) getRemote, Int64 count, Int64 max) async {
  T local = await getLocal(max);
  T? remote = await getRemote(max);
  while (local != remote && max - count >= Int64.ZERO) {
    max--;
    count--;
    local = await getLocal(max);
    remote = await getRemote(max);
  }
  if (local == remote) return remote;
  return null;
}

Future<T?> narySearch<T>(
    Future<T> Function(Int64) getLocal,
    Future<T?> Function(Int64) getRemote,
    Rational searchSpaceTarget,
    Int64 min,
    Int64 max) async {
  Future<T?> f(Int64 max, Int64 min, T? ifNull) async {
    if (min == max) {
      final localValue = await getLocal(min);
      final remoteValue = await getRemote(min);
      if (localValue == remoteValue) {
        return remoteValue;
      } else {
        return ifNull;
      }
    } else {
      final targetHeight = (min + (max - min) * searchSpaceTarget.floor());
      final localValue = await getLocal(targetHeight);
      final remoteValue = await getRemote(targetHeight);
      if (remoteValue == localValue) {
        return f(targetHeight + 1, max, remoteValue);
      } else {
        return f(min, targetHeight, null);
      }
    }
  }

  return f(min, max, null);
}

class SortedPeerInterface extends PeerBlockchainInterface {
  final Map<PeerBlockchainInterface, int> scores;
  SortedPeerInterface(Iterable<PeerBlockchainInterface> interfaces)
      : scores = {for (final i in interfaces) i: 0};

  Future<T> useNextInterface<T>(
      Future<T> Function(PeerBlockchainInterface) f) async {
    final interface =
        scores.entries.reduce((a, b) => a.value < b.value ? a : b).key;
    scores[interface] = scores[interface]! + 1;
    final r = await f(interface);
    scores[interface] = scores[interface]! - 1;
    return r;
  }

  @override
  Future<BlockId?> blockIdAtHeight(Int64 height) =>
      useNextInterface((interface) => interface.blockIdAtHeight(height));

  @override
  Future<BlockId> commonAncestor() =>
      Future.error(UnsupportedError('commonAncestor'));

  @override
  Future<BlockBody?> fetchBody(BlockId id) =>
      useNextInterface((interface) => interface.fetchBody(id));

  @override
  Future<BlockHeader?> fetchHeader(BlockId id) =>
      useNextInterface((interface) => interface.fetchHeader(id));

  @override
  Future<Transaction?> fetchTransaction(TransactionId id) =>
      useNextInterface((interface) => interface.fetchTransaction(id));

  @override
  Future<BlockId> nextBlockAdoption() =>
      Future.error(UnsupportedError('nextBlockAdoption'));

  @override
  Future<TransactionId> nextTransactionNotification() =>
      Future.error(UnsupportedError('nextTransactionNotification'));

  @override
  Future<Uint8List> ping(Uint8List message) =>
      Future.error(UnsupportedError('ping'));

  @override
  Future<PublicP2PState> publicState() =>
      Future.error(UnsupportedError('publicState'));
}
