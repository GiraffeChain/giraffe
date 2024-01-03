import 'dart:async';
import 'dart:io';

import 'package:blockchain/common/block_height_tree.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain/common/utils.dart';
import 'package:blockchain/config.dart';
import 'package:blockchain/consensus/consensus.dart';
import 'package:blockchain/consensus/models/protocol_settings.dart';
import 'package:blockchain/data_stores.dart';
import 'package:blockchain/genesis.dart';
import 'package:blockchain/ledger/ledger.dart';
import 'package:blockchain/network/util.dart';
import 'package:blockchain/private_testnet.dart';
import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/clock.dart';
import 'package:blockchain/common/parent_child_tree.dart';
import 'package:blockchain/crypto/ed25519.dart';
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

class BlockchainCore {
  final Clock clock;
  final DataStores dataStores;
  final ParentChildTree<BlockId> parentChildTree;
  final BlockHeightTree blockHeightTree;
  final Consensus consensus;
  final Ledger ledger;

  BlockchainCore(
      {required this.clock,
      required this.dataStores,
      required this.parentChildTree,
      required this.blockHeightTree,
      required this.consensus,
      required this.ledger});

  final Logger log = Logger("Blockchain.Core");

  static Resource<BlockchainCore> make(
      BlockchainConfig config, DComputeImpl isolate) {
    final genesisTimestamp = config.genesis.timestamp;

    final log = Logger("Blockchain.Core.Init");

    final genesisBaseDir =
        Directory("${Directory.systemTemp.path}/blockchain-genesis");

    return Resource.pure(())
        .tapLog(log, (_) => "Initializing")
        .tapLogFinalize(log, "Terminated")
        .evalMap((_) async => PrivateTestnet.initTo(
              genesisBaseDir,
              genesisTimestamp,
              config.genesis.stakes,
              ProtocolSettings.defaultSettings.kesTreeHeight,
            ))
        .flatMap(
          (genesisBlockId) => Resource.eval(() => Genesis.loadFromDisk(
              Directory(
                  "${genesisBaseDir.path}/${genesisBlockId.show}/genesis"),
              genesisBlockId)).flatMap(
            (genesisBlock) => DataStores.makePersistent(Directory(
                    DataStores.interpolateBlockId(
                        config.data.dataDir, genesisBlockId)))
                .evalTap((d) async {
              if (!await d.isInitialized(genesisBlockId)) {
                await d.init(genesisBlock);
              }
            }).flatMap((dataStores) {
              final genesisBlockId = genesisBlock.header.id;

              log.info(
                  "Genesis id=${genesisBlockId.show} timestamp=$genesisTimestamp");

              final currentEventIdGetterSetters =
                  CurrentEventIdGetterSetters(dataStores.currentEventIds);

              final parentChildTree = ParentChildTreeImpl<BlockId>(
                dataStores.parentChildTree.get,
                dataStores.parentChildTree.put,
                genesisBlock.header.parentHeaderId,
              );
              final protocolSettings =
                  ProtocolSettings.fromMap(genesisBlock.header.settings);

              log.info("Protocol settings=$protocolSettings");

              final clock = ClockImpl(
                protocolSettings.slotDuration,
                protocolSettings.epochLength,
                protocolSettings.operationalPeriodLength,
                genesisTimestamp,
                protocolSettings.forwardBiasedSlotWindow,
              );
              return Resource.eval(() async {
                final canonicalHeadId =
                    await currentEventIdGetterSetters.canonicalHead.get();
                final canonicalHead =
                    await dataStores.headers.getOrRaise(canonicalHeadId);
                log.info(
                    "Canonical head id=${canonicalHeadId.show} height=${canonicalHead.height} slot=${canonicalHead.slot}");
              })
                  .evalMap(
                      (_) => currentEventIdGetterSetters.blockHeightTree.get())
                  .map((eventId) => makeBlockHeightTree(
                      dataStores.blockHeightTree,
                      eventId,
                      dataStores.headers.getOrRaise,
                      parentChildTree,
                      currentEventIdGetterSetters.blockHeightTree.set))
                  .flatMap(
                    (blockHeightTree) => Consensus.make(
                            protocolSettings,
                            dataStores,
                            clock,
                            genesisBlock,
                            currentEventIdGetterSetters,
                            parentChildTree,
                            blockHeightTree,
                            isolate)
                        .flatMap(
                      (consensus) => Ledger.make(
                        dataStores,
                        currentEventIdGetterSetters,
                        parentChildTree,
                        clock,
                      ).map((ledger) => BlockchainCore(
                            clock: clock,
                            dataStores: dataStores,
                            parentChildTree: parentChildTree,
                            blockHeightTree: blockHeightTree,
                            consensus: consensus,
                            ledger: ledger,
                          )),
                    ),
                  );
            }),
          ),
        )
        .tapLog(log, (_) => "Initialized");
  }

  Future<void> processBlock(Block block, {bool compareAndAdopt = true}) async {
    final transactions = await Future.wait(
        block.body.transactionIds.map(dataStores.transactions.getOrRaise));
    final fullBlock = FullBlock(
        header: block.header,
        fullBody: FullBlockBody(transactions: transactions));
    return await processFullBlock(fullBlock, compareAndAdopt: compareAndAdopt);
  }

  Future<void> processFullBlock(FullBlock block,
      {bool compareAndAdopt = true}) async {
    final id = await block.header.id;
    final localBlockAtHeight =
        await consensus.localChain.blockIdAtHeight(block.header.height);
    if (id == localBlockAtHeight) {
      log.info("Block id=${id.show} is already adopted");
      return;
    }

    final body =
        BlockBody(transactionIds: block.fullBody.transactions.map((t) => t.id));
    try {
      log.info("Validating id=${id.show}");
      await log.timedInfoAsync(
          () => validateBlock(id, Block(header: block.header, body: body)),
          messageF: (duration) => "Validation took $duration");
    } on Exception catch (e) {
      log.warning("Failed to validate block", e);
      rethrow;
    }
    await dataStores.bodies.put(id, body);
    if (compareAndAdopt) {
      final currentHead = await consensus.localChain.currentHead;
      final selectedChain = await log.timedInfoAsync(
          () => consensus.chainSelection.select(id, currentHead),
          messageF: (duration) => "Chain Selection took $duration");
      if (selectedChain == id) {
        await consensus.localChain.adopt(id);
        log.info(
            "Adopted id=${id.show} height=${block.header.height} slot=${block.header.slot} transactionCount=${block.fullBody.transactions.length} stakingAddress=${block.header.address.show}");
      } else {
        log.info(
            "Current local head id=${currentHead.show} is better than remote id=${id.show}");
      }
    }
  }

  Future<void> validateBlock(BlockId id, Block block) async {
    await parentChildTree.assocate(id, block.header.parentHeaderId);
    await dataStores.headers.put(id, block.header);

    final errors = await consensus.blockHeaderValidation.validate(block.header);
    throwErrors() async {
      if (errors.isNotEmpty) {
        // TODO: ParentChildTree disassociate
        await dataStores.headers.remove(id);
        throw Exception("Invalid block. reason=$errors");
      }
    }

    await throwErrors();

    errors.addAll(await ledger.headerToBodyValidation.validate(block));

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

class BlockchainRpc {
  static final log = Logger("Blockchain.RPC");
  static Resource<void> make(
          BlockchainCore blockchain, BlockchainConfig config) =>
      rpc
          .serveRpcs(
            config.rpc.bindHost,
            config.rpc.bindPort,
            rpc.NodeRpcServiceImpl(blockchain: blockchain),
            rpc.StakerSupportRpcImpl(blockchain: blockchain),
          )
          .tapLog(
              log,
              (_) =>
                  "Served on host=${config.rpc.bindHost} port=${config.rpc.bindPort}")
          .tapLogFinalize(log, "Terminating");
}

class BlockchainP2P {
  static final log = Logger("Blockchain.P2P");
  static Resource<Future<void>> make(
          BlockchainCore blockchain, BlockchainConfig config) =>
      Resource.pure(())
          .evalFlatMap((_) async {
            log.info("Preparing P2P Network");

            final p2pKey = await ed25519.generateKeyPair();
            final localPeerId = PeerId(value: p2pKey.vk);
            log.info(
                "Local peer id=${localPeerId.show} publicHost=${config.p2p.publicHost} publicPort=${config.p2p.publicPort}");
            final localPeer = ConnectedPeer(
              peerId: localPeerId,
              host: config.p2p.publicHost.stringValue,
              port: config.p2p.publicPort.uint32Value,
            );
            void Function(String, int) connect = (_, __) {};
            final socketHandlerResource =
                (Socket socket) => Resource.make(() async {
                      log.info(
                          "Socket connected at host=${socket.remoteAddress} port=${socket.remotePort}");
                      return (
                        socket: socket,
                        remoteAddress: socket.remoteAddress,
                        remotePort: socket.remotePort
                      );
                    }, (t) async {
                      log.info(
                          "Socket closing at host=${t.remoteAddress} port=${t.remotePort}");
                      t.socket.destroy();
                      await t.socket.done;
                    }).map((t) => t.socket);
            return PeersManager.make(
              localPeer: localPeer,
              localPeerKeyPair: p2pKey,
              magicBytes: config.p2p.magicBytes,
              blockchain: blockchain,
              connect: (host, port) => connect(host, port),
            )
                .map((peersManager) => P2PServer(
                      config.p2p.bindHost,
                      config.p2p.bindPort,
                      (socket) => socketHandlerResource(socket)
                          .use(
                            (socket) => peersManager
                                .handleConnection(socket)
                                .onError((e, stacktrace) => log.warning(
                                    "P2P Connection Error", e, stacktrace)),
                          )
                          .ignore(),
                    ))
                .tap((server) => connect = server.connectOutbound);
          })
          .flatMap((p2pServer) => p2pServer.start().flatMap((f1) =>
              Resource.forStreamSubscription(() => Stream.fromIterable(
                      config.p2p.knownPeers)
                  .map((s) => s.split(":"))
                  .map((parsed) => p2pServer.connectOutbound(parsed[0], int.parse(parsed[1])).ignore())
                  .listen((_) {})).map((subscription) => subscription.asFuture()).map((f2) => Future.wait([f1, f2]))))
          .tapLog(log, (_) => "Served on host=${config.p2p.bindHost} port=${config.p2p.bindPort}")
          .tapLogFinalize(log, "Terminating");
}
