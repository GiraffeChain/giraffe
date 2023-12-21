import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/interpreters/in_memory_store.dart';
import 'package:blockchain/consensus/utils.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:blockchain/common/algebras/store_algebra.dart';

class DataStores {
  final StoreAlgebra<BlockId, (Int64, BlockId)> parentChildTree;
  final StoreAlgebra<int, BlockId> currentEventIds;
  final StoreAlgebra<BlockId, SlotData> slotData;
  final StoreAlgebra<BlockId, BlockHeader> headers;
  final StoreAlgebra<BlockId, BlockBody> bodies;
  final StoreAlgebra<TransactionId, Transaction> transactions;
  final StoreAlgebra<TransactionId, List<int>> spendableBoxIds;
  final StoreAlgebra<Int64, BlockId> epochBoundaries;
  final StoreAlgebra<void, Int64> activeStake;
  final StoreAlgebra<void, Int64> inactiveStake;
  final StoreAlgebra<StakingAddress, ActiveStaker> activeStakers;
  final StoreAlgebra<Int64, BlockId> blockHeightTree;

  DataStores({
    required this.parentChildTree,
    required this.currentEventIds,
    required this.slotData,
    required this.headers,
    required this.bodies,
    required this.transactions,
    required this.spendableBoxIds,
    required this.epochBoundaries,
    required this.activeStake,
    required this.inactiveStake,
    required this.activeStakers,
    required this.blockHeightTree,
  });

  static Future<DataStores> init(FullBlock genesisBlock) async {
    makeDb<Key, Value>() => InMemoryStore<Key, Value>();

    final stores = DataStores(
      parentChildTree: makeDb(),
      currentEventIds: makeDb(),
      slotData: makeDb(),
      headers: makeDb(),
      bodies: makeDb(),
      transactions: makeDb(),
      spendableBoxIds: makeDb(),
      epochBoundaries: makeDb(),
      activeStake: makeDb(),
      inactiveStake: makeDb(),
      activeStakers: makeDb(),
      blockHeightTree: makeDb(),
    );

    final genesisBlockId = await genesisBlock.header.id;

    await stores.currentEventIds
        .put(CurreventEventIdGetterSetterIndices.CanonicalHead, genesisBlockId);
    for (final key in [
      CurreventEventIdGetterSetterIndices.ConsensusData,
      CurreventEventIdGetterSetterIndices.EpochBoundaries,
      CurreventEventIdGetterSetterIndices.BlockHeightTree,
      CurreventEventIdGetterSetterIndices.BoxState,
      CurreventEventIdGetterSetterIndices.Mempool,
    ]) {
      await stores.currentEventIds.put(key, genesisBlock.header.parentHeaderId);
    }

    await stores.slotData
        .put(genesisBlockId, await genesisBlock.header.slotData);
    await stores.headers.put(genesisBlockId, genesisBlock.header);
    await stores.bodies.put(
        genesisBlockId,
        BlockBody()
          ..transactionIds.addAll(
            [
              for (final transaction in genesisBlock.fullBody.transactions)
                await transaction.id
            ],
          ));
    for (final transaction in genesisBlock.fullBody.transactions) {
      await stores.transactions.put(await transaction.id, transaction);
    }
    await stores.blockHeightTree
        .put(Int64(0), genesisBlock.header.parentHeaderId);
    if (!await stores.activeStake.contains("")) {
      await stores.activeStake.put("", Int64.ZERO);
    }
    if (!await stores.inactiveStake.contains("")) {
      await stores.inactiveStake.put("", Int64.ZERO);
    }
    return stores;
  }
}

class CurreventEventIdGetterSetterIndices {
  static const CanonicalHead = 0;
  static const ConsensusData = 1;
  static const EpochBoundaries = 2;
  static const BlockHeightTree = 3;
  static const BoxState = 4;
  static const Mempool = 5;
}

class CurrentEventIdGetterSetters {
  final StoreAlgebra<int, BlockId> store;

  CurrentEventIdGetterSetters(this.store);

  GetterSetter get canonicalHead => GetterSetter.forByte(
      store, CurreventEventIdGetterSetterIndices.CanonicalHead);

  GetterSetter get consensusData => GetterSetter.forByte(
      store, CurreventEventIdGetterSetterIndices.ConsensusData);

  GetterSetter get epochBoundaries => GetterSetter.forByte(
      store, CurreventEventIdGetterSetterIndices.EpochBoundaries);

  GetterSetter get blockHeightTree => GetterSetter.forByte(
      store, CurreventEventIdGetterSetterIndices.BlockHeightTree);

  GetterSetter get boxState =>
      GetterSetter.forByte(store, CurreventEventIdGetterSetterIndices.BoxState);

  GetterSetter get mempool =>
      GetterSetter.forByte(store, CurreventEventIdGetterSetterIndices.Mempool);
}

class GetterSetter {
  final Future<BlockId> Function() get;
  final Future<void> Function(BlockId) set;

  GetterSetter(this.get, this.set);

  factory GetterSetter.forByte(StoreAlgebra<int, BlockId> store, int byte) =>
      GetterSetter(
          () => store.getOrRaise(byte), (value) => store.put(byte, value));
}
