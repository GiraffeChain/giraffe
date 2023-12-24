import 'dart:async';
import 'dart:typed_data';

import 'package:blockchain/common/block_height_tree.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain/config.dart';
import 'package:blockchain/consensus/consensus.dart';
import 'package:blockchain/consensus/models/protocol_settings.dart';
import 'package:blockchain/data_stores.dart';
import 'package:blockchain/ledger/ledger.dart';
import 'package:blockchain/minting/minting.dart';
import 'package:blockchain/private_testnet.dart';
import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/clock.dart';
import 'package:blockchain/common/parent_child_tree.dart';
import 'package:blockchain/consensus/utils.dart';
import 'package:blockchain/crypto/ed25519.dart';
import 'package:blockchain/crypto/kes.dart';
import 'package:blockchain/crypto/utils.dart';
import 'package:blockchain/ledger/models/body_validation_context.dart';
import 'package:blockchain/network/p2p_server.dart';
import 'package:blockchain/network/peers_manager.dart';
import 'package:blockchain/traversal.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain/rpc/server.dart' as rpc;
import 'package:fixnum/fixnum.dart';
import 'package:fpdart/fpdart.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/streams.dart';

class Blockchain {
  final BlockchainConfig config;
  final Clock clock;
  final DataStores dataStores;
  final ParentChildTree<BlockId> parentChildTree;
  final BlockHeightTree blockHeightTree;
  final Consensus consensus;
  final Ledger ledger;
  final Minting? minting;
  final P2PServer p2pServer;

  final log = Logger("Blockchain");

  Blockchain(
    this.config,
    this.clock,
    this.dataStores,
    this.parentChildTree,
    this.blockHeightTree,
    this.consensus,
    this.ledger,
    this.minting,
    this.p2pServer,
  );

  static Resource<Blockchain> make(
      BlockchainConfig config, DComputeImpl isolate) {
    final genesisTimestamp = config.genesis.timestamp;

    final log = Logger("Blockchain.Init");

    return Resource.pure(())
        .tapLog(log, (_) => "Initializing blockchain")
        .tapLogFinalize(log, "Blockchain terminated")
        .tapLog(log, (_) => "Genesis timestamp=$genesisTimestamp")
        .flatMap((_) => Resource.eval(() => PrivateTestnet.stakerInitializers(
                genesisTimestamp,
                config.genesis.stakerCount,
                TreeHeight(ProtocolSettings.defaultSettings.kesKeyHours,
                    ProtocolSettings.defaultSettings.kesKeyMinutes)))
            .tapLog(log, (_) => "Staker initializers prepared")
            .flatMap((stakerInitializers) => Resource.eval(
                  () => PrivateTestnet.config(genesisTimestamp,
                      stakerInitializers, config.genesis.stakes),
                ).flatMap(
                  (genesisConfig) =>
                      Resource.eval(() => genesisConfig.block).flatMap(
                    (genesisBlock) =>
                        Resource.eval(() => DataStores.init(genesisBlock))
                            .flatMap((dataStores) {
                      final genesisBlockId = genesisBlock.header.id;

                      final currentEventIdGetterSetters =
                          CurrentEventIdGetterSetters(
                              dataStores.currentEventIds);

                      final parentChildTree = ParentChildTreeImpl<BlockId>(
                        dataStores.parentChildTree.get,
                        dataStores.parentChildTree.put,
                        genesisBlock.header.parentHeaderId,
                      );
                      final protocolSettings = ProtocolSettings.fromMap(
                          genesisBlock.header.settings);

                      final clock = ClockImpl(
                        protocolSettings.slotDuration,
                        protocolSettings.epochLength,
                        genesisTimestamp,
                        protocolSettings.forwardBiasedSlotWindow,
                      );
                      return Resource.eval(() =>
                              currentEventIdGetterSetters.blockHeightTree.get())
                          .map((eventId) => makeBlockHeightTree(
                              dataStores.blockHeightTree,
                              eventId,
                              dataStores.slotData,
                              parentChildTree,
                              currentEventIdGetterSetters.blockHeightTree.set))
                          .flatMap((blockHeightTree) => Resource.eval(() =>
                                  currentEventIdGetterSetters.canonicalHead
                                      .get()).flatMap(
                                (canonicalHeadId) => Resource.eval(() =>
                                    dataStores.slotData
                                        .getOrRaise(canonicalHeadId)).flatMap(
                                  (canonicalHeadSlotData) => Resource.eval(() =>
                                          parentChildTree.assocate(
                                              genesisBlockId,
                                              genesisBlock
                                                  .header.parentHeaderId))
                                      .flatMap((_) => Consensus.make(
                                          protocolSettings,
                                          dataStores,
                                          clock,
                                          genesisBlock,
                                          currentEventIdGetterSetters,
                                          parentChildTree,
                                          blockHeightTree,
                                          isolate))
                                      .flatMap(
                                        (consensus) => Ledger.make(
                                                dataStores,
                                                currentEventIdGetterSetters,
                                                parentChildTree)
                                            .flatMap(
                                          (ledger) => ((config.genesis
                                                              .localStakerIndex !=
                                                          null &&
                                                      config.genesis
                                                              .localStakerIndex! >=
                                                          0)
                                                  ? Minting.makeForConsensus(
                                                      protocolSettings,
                                                      clock,
                                                      consensus,
                                                      ledger.blockPacker,
                                                      canonicalHeadSlotData,
                                                      stakerInitializers[config
                                                          .genesis
                                                          .localStakerIndex!],
                                                      ConcatStream([
                                                        Stream.value(
                                                                canonicalHeadSlotData)
                                                            .asyncMap((d) => clock
                                                                .delayedUntilSlot(
                                                                    d.slotId
                                                                        .slot)
                                                                .then(
                                                                    (_) => d)),
                                                        consensus.localChain
                                                            .adoptions
                                                            .asyncMap(dataStores
                                                                .slotData
                                                                .getOrRaise),
                                                      ]),
                                                    )
                                                  : Resource.pure<Minting?>(
                                                          null)
                                                      .tapLog(
                                                          log,
                                                          (_) =>
                                                              "Local staking disabled"))
                                              .evalMap((minting) async {
                                            log.info("Preparing P2P Network");

                                            final p2pKey =
                                                await ed25519.generateKeyPair();
                                            final peersManager = PeersManager(
                                                p2pKey,
                                                Uint8List.fromList(
                                                    List.generate(
                                                        32, (i) => i)));
                                            final p2pServer = P2PServer(
                                              config.p2p.bindHost,
                                              config.p2p.bindPort,
                                              (socket) => peersManager
                                                  .handleConnection(socket)
                                                  .onError((error, stackTrace) {
                                                log.warning(
                                                    "P2P Connection failure",
                                                    error,
                                                    stackTrace);
                                                socket.destroy();
                                              }),
                                            );
                                            return Blockchain(
                                              config,
                                              clock,
                                              dataStores,
                                              parentChildTree,
                                              blockHeightTree,
                                              consensus,
                                              ledger,
                                              minting,
                                              p2pServer,
                                            );
                                          }),
                                        ),
                                      ),
                                ),
                              ));
                    }),
                  ),
                ))
            .tap((_) => log.info("Blockchain Initialized")));
  }

  Future<void> processBlock(Block block) async {
    final transactions = await Future.wait(
        block.body.transactionIds.map(dataStores.transactions.getOrRaise));
    final fullBlock = FullBlock(
        header: block.header,
        fullBody: FullBlockBody(transactions: transactions));
    return await processFullBlock(fullBlock);
  }

  Future<void> processFullBlock(FullBlock block) async {
    final id = await block.header.id;

    final body =
        BlockBody(transactionIds: block.fullBody.transactions.map((t) => t.id));
    await validateBlock(id, Block(header: block.header, body: body));
    await dataStores.bodies.put(id, body);
    if (await consensus.chainSelection
            .select(id, await consensus.localChain.currentHead) ==
        id) {
      log.info("Adopting id=${id.show}");
      await consensus.localChain.adopt(id);
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

  Future<void> processTransaction(Transaction transaction) async {
    final validationErrors =
        await ledger.transactionSyntaxValidation.validate(transaction);
    if (validationErrors.isNotEmpty)
      throw ArgumentError.value(transaction, validationErrors.first);
    await dataStores.transactions.put(transaction.id, transaction);
    await ledger.mempool.add(transaction.id);
  }

  Resource<void> get _makeRpcServer => rpc.serveRpcs(
        config.rpc.bindHost,
        config.rpc.bindPort,
        rpc.NodeRpcServiceImpl(
          traversal: traversal,
          dataStores: dataStores,
          onBroadcastTransaction: processTransaction,
          blockIdAtHeight: consensus.localChain.blockIdAtHeight,
        ),
        rpc.StakerSupportRpcImpl(
          onBroadcastBlock: processBlock,
          stakerTracker: consensus.stakerTracker,
          packBlock: (parentBlockId, targetSlot) =>
              Stream.fromFuture(dataStores.headers.getOrRaise(parentBlockId))
                  .map((h) => h.height)
                  .asyncExpand((parentHeight) => ledger.blockPacker
                      .streamed(parentBlockId, parentHeight + 1, targetSlot)
                      .map((fullBody) => BlockBody(
                          transactionIds:
                              fullBody.transactions.map((t) => t.id)))),
          calculateEta: (parentId, slot) => dataStores.slotData
              .getOrRaise(parentId)
              .then((parentSlotData) => consensus.etaCalculation
                  .etaToBe(parentSlotData.slotId, slot)),
        ),
      );

  Resource<void> run() => p2pServer
      .start()
      .flatMap((_) => Resource.forStreamSubscription(() =>
          Stream.fromIterable(config.p2p.knownPeers)
              .map((s) => s.split(":"))
              .map((parsed) =>
                  p2pServer.connectOutbound(parsed[0], int.parse(parsed[1])))
              .listen((_) {})))
      .tapLog(log, (_) => "P2P Initialized")
      .tapLogFinalize(log, "Terminating P2P")
      .tapLog(log, (_) => "Initializing RPC")
      .tapLogFinalize(log, "RPC Terminated")
      .flatMap((_) => _makeRpcServer)
      .tapLog(log, (_) => "RPC Initialized")
      .tapLogFinalize(log, "Terminating RPC")
      .flatMap(
        (_) => (minting != null)
            ? Resource.forStreamSubscription(() => minting!.blockProducer.blocks
                .asyncMap(processFullBlock)
                .listen((event) {}))
            : Resource.pure(()),
      )
      .voidResult;

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
