import 'dart:async';
import 'dart:typed_data';

import 'package:blockchain/common/block_height_tree.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain/config.dart';
import 'package:blockchain/consensus/consensus.dart';
import 'package:blockchain/data_stores.dart';
import 'package:blockchain/ledger/mempool.dart';
import 'package:blockchain/ledger/ledger.dart';
import 'package:blockchain/minting/block_packer.dart';
import 'package:blockchain/minting/block_producer.dart';
import 'package:blockchain/minting/operational_key_maker.dart';
import 'package:blockchain/minting/secure_store.dart';
import 'package:blockchain/minting/staking.dart';
import 'package:blockchain/minting/vrf_calculator.dart';
import 'package:blockchain/private_testnet.dart';
import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/clock.dart';
import 'package:blockchain/common/parent_child_tree.dart';
import 'package:blockchain/consensus/models/vrf_config.dart';
import 'package:blockchain/consensus/utils.dart';
import 'package:blockchain/crypto/ed25519.dart';
import 'package:blockchain/crypto/kes.dart';
import 'package:blockchain/crypto/utils.dart';
import 'package:blockchain/ledger/models/body_validation_context.dart';
import 'package:blockchain/network/p2p_server.dart';
import 'package:blockchain/network/peers_manager.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain/wallet/wallet.dart';
import 'package:fixnum/fixnum.dart';
import 'package:fpdart/fpdart.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/streams.dart';

class Blockchain {
  final ClockAlgebra clock;
  final DataStores dataStores;
  final ParentChildTreeAlgebra<BlockId> parentChildTree;
  final Consensus consensus;
  final Ledger ledger;
  final BlockProducerAlgebra blockProducer;
  final P2PServer p2pServer;
  final WalletESS walletESS;

  final log = Logger("Blockchain");

  Blockchain(
    this.clock,
    this.dataStores,
    this.parentChildTree,
    this.consensus,
    this.ledger,
    this.blockProducer,
    this.p2pServer,
    this.walletESS,
  );

  static Resource<Blockchain> init(
      BlockchainConfig config, DComputeImpl isolate) {
    final genesisTimestamp = config.genesis.timestamp;

    final vrfConfig = VrfConfig(
      lddCutoff: config.consensus.vrfLddCutoff,
      precision: config.consensus.vrfPrecision,
      baselineDifficulty: config.consensus.vrfBaselineDifficulty,
      amplitude: config.consensus.vrfAmpltitude,
    );

    final clock = Clock(
      config.consensus.slotDuration,
      config.consensus.epochLength,
      genesisTimestamp,
      config.consensus.forwardBiastedSlotWindow,
    );

    return Resource.pure(Logger("Blockchain.Init"))
        .flatTap((log) => Resource.make(
            () => Future.sync(() => log.info("Initializing blockchain")),
            (_) => Future.sync(() => log.info("Terminating blockchain"))))
        .tap((log) => log.info("Genesis timestamp=$genesisTimestamp"))
        .flatMap((log) => Resource.eval(() => PrivateTestnet.stakerInitializers(
                genesisTimestamp,
                config.genesis.stakerCount,
                TreeHeight(config.consensus.kesKeyHours,
                    config.consensus.kesKeyMinutes)))
            .flatMap((stakerInitializers) {
              log.info("Staker initializers prepared");

              final stakerInitializer =
                  stakerInitializers[config.genesis.localStakerIndex!];

              return Resource.eval(() => PrivateTestnet.config(
                  genesisTimestamp,
                  stakerInitializers,
                  config.genesis
                      .stakes)).flatMap((genesisConfig) => Resource.eval(
                  () =>
                      genesisConfig.block).flatMap((genesisBlock) =>
                  Resource.eval(() => DataStores.init(genesisBlock))
                      .flatMap((dataStores) {
                    final genesisBlockId = genesisBlock.header.id;

                    final currentEventIdGetterSetters =
                        CurrentEventIdGetterSetters(dataStores.currentEventIds);

                    final parentChildTree = ParentChildTree<BlockId>(
                      dataStores.parentChildTree.get,
                      dataStores.parentChildTree.put,
                      genesisBlock.header.parentHeaderId,
                    );
                    return Resource.eval(() =>
                            currentEventIdGetterSetters.blockHeightTree.get())
                        .map((eventId) => makeBlockHeightTree(
                            dataStores.blockHeightTree,
                            eventId,
                            dataStores.slotData,
                            parentChildTree,
                            currentEventIdGetterSetters.blockHeightTree.set))
                        .flatMap((blockHeightTree) {
                      final secureStore = InMemorySecureStore();

                      return Resource.eval(() => currentEventIdGetterSetters.canonicalHead.get()).flatMap((canonicalHeadId) => Resource.eval(() => dataStores.slotData.getOrRaise(canonicalHeadId)).flatMap((canonicalHeadSlotData) => Resource.eval(
                              () => parentChildTree.assocate(genesisBlockId, genesisBlock.header.parentHeaderId))
                          .flatMap((_) => Consensus.make(
                              vrfConfig,
                              dataStores,
                              clock,
                              genesisBlock,
                              currentEventIdGetterSetters,
                              parentChildTree,
                              blockHeightTree,
                              isolate))
                          .flatMap((consensus) => Ledger.make(dataStores, currentEventIdGetterSetters, parentChildTree).evalFlatMap((ledger) async {
                                log.info("Preparing OperationalKeyMaker");

                                final vrfCalculator = VrfCalculator(
                                    stakerInitializer.vrfKeyPair.sk,
                                    clock,
                                    consensus.leaderElectionValidation,
                                    vrfConfig);

                                final operationalKeyMaker =
                                    await OperationalKeyMaker.init(
                                  canonicalHeadSlotData.slotId,
                                  config.consensus.operationalPeriodLength,
                                  Int64(0),
                                  stakerInitializer.stakingAddress,
                                  secureStore,
                                  clock,
                                  vrfCalculator,
                                  consensus.etaCalculation,
                                  consensus.consensusValidationState,
                                  stakerInitializer.kesKeyPair.sk,
                                );

                                log.info("Preparing Staking");

                                final staker = Staking(
                                  stakerInitializer.stakingAddress,
                                  stakerInitializer.vrfKeyPair.vk,
                                  operationalKeyMaker,
                                  consensus.consensusValidationState,
                                  consensus.etaCalculation,
                                  vrfCalculator,
                                  consensus.leaderElectionValidation,
                                );

                                log.info("Preparing mempool");
                                final mempool = Mempool(
                                    dataStores.bodies.getOrRaise,
                                    parentChildTree,
                                    await currentEventIdGetterSetters.mempool
                                        .get(),
                                    Duration(minutes: 5));

                                log.info("Preparing BlockProducer");

                                final blockPacker = BlockPacker(
                                    mempool,
                                    dataStores.transactions.getOrRaise,
                                    dataStores.transactions.contains,
                                    BlockPacker.makeBodyValidator(
                                        ledger.bodySyntaxValidation,
                                        ledger.bodySemanticValidation,
                                        ledger.bodyAuthorizationValidation));

                                final blockProducer = BlockProducer(
                                  ConcatStream([
                                    Stream.value(canonicalHeadSlotData)
                                        .asyncMap((d) => clock
                                            .delayedUntilSlot(d.slotId.slot)
                                            .then((_) => d)),
                                    consensus.localChain.adoptions.asyncMap(
                                        dataStores.slotData.getOrRaise),
                                  ]),
                                  staker,
                                  clock,
                                  blockPacker,
                                );

                                log.info("Initializing Wallet ESS");
                                final wallet = Wallet.empty();
                                await wallet.addPrivateGenesisKey();
                                final walletESS = WalletEventSourcedState.make(
                                  wallet,
                                  dataStores.bodies.getOrRaise,
                                  dataStores.transactions.getOrRaise,
                                  parentChildTree,
                                  genesisBlock.header.parentHeaderId,
                                );

                                log.info("Preparing P2P Network");

                                final p2pKey = await ed25519.generateKeyPair();
                                final peersManager = PeersManager(
                                    p2pKey,
                                    Uint8List.fromList(
                                        List.generate(32, (i) => i)));
                                final p2pServer = P2PServer(
                                  config.p2p.bindHost,
                                  config.p2p.bindPort,
                                  (socket) => peersManager
                                      .handleConnection(socket)
                                      .onError((error, stackTrace) {
                                    log.warning("P2P Connection failure", error,
                                        stackTrace);
                                    socket.destroy();
                                  }),
                                );

                                for (final peer in config.p2p.knownPeers) {
                                  final parsed = peer.split(":");
                                  p2pServer.connectOutbound(
                                      parsed[0], int.parse(parsed[1]));
                                }

                                return p2pServer.start().map((_) => Blockchain(
                                      clock,
                                      dataStores,
                                      parentChildTree,
                                      consensus,
                                      ledger,
                                      blockProducer,
                                      p2pServer,
                                      walletESS,
                                    ));
                              }))));
                    });
                  })));
            })
            .tap((_) => log.info("Blockchain Initialized"))
            .flatTap((blockchain) => blockchain.run()));
  }

  Future<void> processBlock(FullBlock block) async {
    final id = await block.header.id;

    final body = BlockBody()
      ..transactionIds.addAll([
        for (final transaction in block.fullBody.transactions)
          await transaction.id
      ]);
    await validateBlock(
        id,
        Block()
          ..header = block.header
          ..body = body);
    await dataStores.bodies.put(id, body);
    if (await consensus.chainSelection
            .select(id, await consensus.localChain.currentHead) ==
        id) {
      log.info("Adopting id=${id.show}");
      consensus.localChain.adopt(id);
    }
  }

  Future<void> validateBlock(BlockId id, Block block) async {
    await parentChildTree.assocate(id, block.header.parentHeaderId);
    await dataStores.slotData.put(id, await block.header.slotData);
    await dataStores.headers.put(id, block.header);

    final errors = await consensus.blockHeaderValidation.validate(block.header);
    throwErrors() async {
      if (errors.isNotEmpty) {
        // TODO: ParentChildTree disassociate
        await dataStores.slotData.remove(id);
        await dataStores.headers.remove(id);
        throw Exception("Invalid block. reason=$errors");
      }
    }

    await throwErrors();

    errors.addAll(await ledger.bodySyntaxValidation.validate(block.body));
    await throwErrors();
    final bodyValidationContext = BodyValidationContext(
        block.header.parentHeaderId, block.header.height, block.header.slot);
    errors.addAll(await ledger.bodySemanticValidation
        .validate(block.body, bodyValidationContext));
    await throwErrors();
    errors
        .addAll(await ledger.bodyAuthorizationValidation.validate(block.body));
    await throwErrors();
  }

  Resource<void> run() => Resource.forStreamSubscription(
          () => blockProducer.blocks.asyncMap(processBlock).listen((event) {}))
      .voidResult;

  Stream<FullBlock> get newBlocks =>
      consensus.localChain.adoptions.asyncMap((id) async {
        final header = await dataStores.headers.getOrRaise(id);
        final body = await dataStores.bodies.getOrRaise(id);
        final transactions = [
          for (final id in body.transactionIds)
            await dataStores.transactions.getOrRaise(id)
        ];
        final fullBlock = FullBlock()
          ..header = header
          ..fullBody = (FullBlockBody()..transactions.addAll(transactions));
        return fullBlock;
      });

  Stream<TraversalStep> get traversal {
    BlockId? lastId = null;
    return consensus.localChain.adoptions
        .asyncExpand((id) => (lastId == null)
            ? Stream.value(TraversalStep_Applied(id))
            : traversalBetween(lastId!, id))
        .map((step) {
      lastId = step.blockId;
      return step;
    });
  }

  Stream<TraversalStep> get traversalFromGenesis =>
      Stream.fromFuture(consensus.localChain.blockIdAtHeight(Int64(1)))
          .asyncExpand((genesisId) =>
              Stream.fromFuture(consensus.localChain.currentHead)
                  .asyncExpand((head) => traversalBetween(genesisId!, head)))
          .concatWith([traversal]);

  Stream<TraversalStep> traversalBetween(BlockId a, BlockId b) =>
      Stream.fromFuture(parentChildTree.findCommmonAncestor(a, b)).expand(
          (unapplyApply) => <TraversalStep>[]
            ..addAll(unapplyApply.$1.tail
                .toNullable()!
                .map((id) => TraversalStep_Unapplied(id)))
            ..addAll(unapplyApply.$2.tail
                .toNullable()!
                .map((id) => TraversalStep_Applied(id))));
}

abstract class TraversalStep {
  final BlockId blockId;

  TraversalStep(this.blockId);
}

class TraversalStep_Applied extends TraversalStep {
  TraversalStep_Applied(super.blockId);
}

class TraversalStep_Unapplied extends TraversalStep {
  TraversalStep_Unapplied(super.blockId);
}
