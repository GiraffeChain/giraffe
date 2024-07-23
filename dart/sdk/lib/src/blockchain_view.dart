import 'package:blockchain_sdk/src/traversal.dart';
import 'protocol_settings.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:rxdart/transformers.dart';

abstract class BlockchainView {
  Future<BlockHeader?> getBlockHeader(BlockId blockId);
  Future<BlockBody?> getBlockBody(BlockId blockId);
  Future<Transaction?> getTransaction(TransactionId transactionId);
  Future<BlockId?> getBlockIdAtHeight(Int64 height);
  Future<BlockId> get canonicalHeadId;
  Future<BlockId> get genesisBlockId;
  Stream<TraversalStep> get traversal;

  Stream<BlockId> get adoptions =>
      traversal.whereType<TraversalStep_Applied>().map((t) => t.blockId);

  Future<BlockHeader> getBlockHeaderOrRaise(BlockId blockId) =>
      getBlockHeader(blockId).then((v) => v!);

  Future<BlockBody> getBlockBodyOrRaise(BlockId blockId) =>
      getBlockBody(blockId).then((v) => v!);

  Future<Transaction> getTransactionOrRaise(TransactionId transactionId) =>
      getTransaction(transactionId).then((v) => v!);

  Future<FullBlock?> getFullBlock(BlockId blockId) async {
    final header = await getBlockHeader(blockId);
    if (header == null) return null;
    final body = await getBlockBody(blockId);
    if (body == null) return null;
    final transactionsResult = <Transaction>[];
    for (final transactionId in body.transactionIds) {
      final transaction = await getTransaction(transactionId);
      if (transaction == null) return null;
      transactionsResult.add(transaction);
    }
    final fullBody = FullBlockBody(transactions: transactionsResult);
    return FullBlock(header: header, fullBody: fullBody);
  }

  Future<FullBlock> getFullBlockOrRaise(BlockId blockId) =>
      getFullBlock(blockId).then((v) => v!);

  Future<BlockHeader> get genesisHeader =>
      genesisBlockId.then(getBlockHeaderOrRaise);

  Future<FullBlock> get genesisBlock =>
      genesisBlockId.then(getFullBlockOrRaise);

  Future<ProtocolSettings> get protocolSettings async {
    final genesis = await genesisBlock;
    return ProtocolSettings.defaultSettings
        .mergeFromMap(genesis.header.settings);
  }

  Stream<FullBlock> get adoptedBlocks =>
      adoptions.asyncMap(getFullBlock).whereNotNull();

  Stream<BlockId> get replay async* {
    Int64 h = Int64(1);
    while (true) {
      final next = await getBlockIdAtHeight(h);
      if (next == null) break;
      yield next;
      h += 1;
    }
  }

  Stream<FullBlock> get replayBlocks =>
      replay.asyncMap(getFullBlock).whereNotNull();

  Future<BlockHeader> get canonicalHead async =>
      getBlockHeaderOrRaise(await canonicalHeadId);

// TODO?
  // Clock? _clock;

  // Future<Clock> get clock async {
  //   if (_clock != null) return _clock!;
  //   final protocol = await protocolSettings;
  //   final genesisTimestamp = (await genesisHeader).timestamp;
  //   final c = ClockImpl(
  //     protocol.slotDuration,
  //     protocol.epochLength,
  //     protocol.operationalPeriodLength,
  //     genesisTimestamp,
  //   );
  //   _clock = c;
  //   return c;
  // }
}
