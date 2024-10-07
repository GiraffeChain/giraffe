import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:giraffe_protocol/src/blockchain/codecs.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/streams.dart';

import '../blockchain_core.dart';
import '../genesis.dart';
import 'network.dart';
import 'peer_interface.dart';
import 'shared_sync.dart';

class PeerBlockchainHandler {
  final BlockchainCore core;
  final PeerState peerState;
  final SharedSync sharedSync;

  PeerBlockchainHandler(
      {required this.core, required this.peerState, required this.sharedSync});

  Stream<void> get handle => MergeStream([
        pingPong,
        peerStateUpdater,
        start,
      ]);

  PeerBlockchainInterface get interface => peerState.interface;

  Stream<void> get pingPong => microPeriodStream(
      period: const Duration(seconds: 1),
      f: () => interface.ping(Uint8List(0)));

  Stream<void> get peerStateUpdater => microPeriodStream(
      period: const Duration(seconds: 5),
      f: () async => peerState.publicState = await interface.publicState());

  Stream<void> get start async* {
    await verifyGenesisAgreement();
    while (true) {
      yield* syncCheck;
    }
  }

  Stream<void> get syncCheck async* {
    final commonAncestor = await interface.commonAncestor();
    final commonAncestorHeader =
        await core.dataStores.headers.getOrRaise(commonAncestor);
    final remoteHeadId = await interface.blockIdAtHeight(Int64.ZERO);
    if (remoteHeadId == null) {
      throw StateError("Remote canonical head not found");
    }
    final remoteHeader = (await core.dataStores.headers.get(remoteHeadId)) ??
        (await interface.fetchHeader(remoteHeadId));
    if (remoteHeader == null) {
      throw StateError("Remote header not found");
    }
    await sharedSync.compare(
        commonAncestorHeader, remoteHeader, peerState.peerId);
    yield* inSync;
  }

  Stream<void> get inSync => RaceStream([
        awaitBetterBlock,
        Stream.fromFuture(sharedSync.syncCompletion()),
        mempoolSync,
      ]);

  Stream<BlockHeader?> get awaitBetterBlock async* {
    Future<BlockId> f = interface.nextBlockAdoption();
    while (true) {
      yield null;
      final blockId = await Future.any(
          [f, Future.delayed(const Duration(seconds: 1)).then((_) => null)]);
      yield null;
      if (blockId != null) {
        final header = await interface.fetchHeader(blockId);
        if (header == null) {
          throw StateError("Remote header not found");
        }
        if (header.parentHeaderId == core.consensus.localChain.head) {
          await checkHeader(core, header);
          final fullBlock = await fetchFullBlock(interface, header);
          await checkBody(core, fullBlock);
          if (header.parentHeaderId == core.consensus.localChain.head) {
            await core.consensus.localChain.adopt(header.id);
          }
        } else {
          yield header;
          return;
        }
      }
    }
  }

  Future<void> verifyGenesisAgreement() async {
    final remoteGenesisId = await interface.blockIdAtHeight(Genesis.height);
    if (remoteGenesisId == null) {
      throw StateError("Remote genesis block not found");
    }
    final localGenesisId = core.consensus.localChain.genesis;
    if (localGenesisId != remoteGenesisId) {
      throw StateError("Genesis Mismatch");
    }
  }

  Stream<void> get mempoolSync async* {
    while (true) {
      yield null;
      final notification = await interface.nextTransactionNotification();
      yield null;
      if (!(await core.dataStores.transactions.contains(notification))) {
        final tx = await interface.fetchTransaction(notification);
        if (tx == null) {
          throw StateError("Remote transaction not found");
        }
        await core.dataStores.transactions.put(tx.id, tx);
        // TODO: mempool
      }
      yield null;
    }
  }

  static final log = Logger("PeerHandler");

  static Future<void> checkHeader(
      BlockchainCore core, BlockHeader header) async {
    log.info("Processing remote block id=${header.id.show}");
    // TODO: validate
    if (!(await core.dataStores.headers.contains(header.id))) {
      await core.dataStores.headers.put(header.id, header);
    }
    await core.blockIdTree.associate(header.id, header.parentHeaderId);
  }

  static Future<void> checkBody(BlockchainCore core, FullBlock block) async {
    // TODO: validate
    if (!(await core.dataStores.bodies.contains(block.header.id))) {
      final body = BlockBody(
          transactionIds:
              block.fullBody.transactions.map((tx) => tx.id).toList());
      await core.dataStores.bodies.put(block.header.id, body);
    }
    await Future.wait(block.fullBody.transactions.map((tx) async {
      if (!(await core.dataStores.transactions.contains(tx.id))) {
        await core.dataStores.transactions.put(tx.id, tx);
      }
    }));
  }

  static Future<FullBlock> fetchFullBlock(
      PeerBlockchainInterface interface, BlockHeader header) async {
    final body = await interface.fetchBody(header.id);
    if (body == null) {
      throw StateError("Remote block body not found");
    }
    final transactions = await Future.wait(body.transactionIds
        .map((txId) => interface.fetchTransaction(txId).then((tx) {
              if (tx == null) {
                throw StateError("Remote transaction not found");
              }
              return tx;
            })));
    return FullBlock(
        header: header, fullBody: FullBlockBody(transactions: transactions));
  }
}

// A stream that computes a value every `period` duration (starting immediately) and yields it, then yields several `null` values at the given `microPeriod` duration.
// Reason: Allows the Stream `cancel` mechanism to trigger sooner
Stream<T?> microPeriodStream<T>(
    {required Duration period,
    required Future<T> Function() f,
    Duration microPeriod = const Duration(milliseconds: 200)}) async* {
  while (true) {
    yield await f();
    await for (final _ in Stream.periodic(microPeriod)
        .take(period.inMicroseconds ~/ microPeriod.inMicroseconds)) {
      yield null;
    }
  }
}
