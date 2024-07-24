import 'dart:async';
import 'dart:io';

import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/block_height_tree.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain/config.dart';
import 'package:blockchain/consensus/consensus.dart';
import 'package:blockchain/data_stores.dart';
import 'package:blockchain/genesis.dart';
import 'package:blockchain/ledger/ledger.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:blockchain/network/util.dart';
import 'package:blockchain/private_testnet.dart';
import 'package:blockchain/common/clock.dart';
import 'package:blockchain/common/parent_child_tree.dart';
import 'package:blockchain/network/p2p_server.dart';
import 'package:blockchain/network/peers_manager.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain/rpc/server.dart' as rpc;
import 'package:fixnum/fixnum.dart';
import 'package:logging/logging.dart';
import 'package:ribs_core/ribs_core.dart';
import 'package:ribs_effect/ribs_effect.dart';

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
        .evalMap((_) => IO.fromFutureF(() => PrivateTestnet.initTo(
              genesisBaseDir,
              genesisTimestamp,
              config.genesis.stakes,
              ProtocolSettings.defaultSettings.kesTreeHeight,
            )))
        .flatMap(
          (genesisBlockId) => Resource.eval(Genesis.loadFromDisk(
                  Directory(
                      "${genesisBaseDir.path}/${genesisBlockId.show}/genesis"),
                  genesisBlockId))
              .flatMap(
            (genesisBlock) => DataStores.makePersistent(Directory(
                    DataStores.interpolateBlockId(
                        config.data.dataDir, genesisBlockId)))
                .evalTap((d) => IO.fromFutureF(() async {
                      if (!await d.isInitialized(genesisBlockId)) {
                        await d.init(genesisBlock);
                      }
                    }))
                .flatMap((dataStores) {
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
              );
              return Resource.eval(IO.fromFutureF(() async {
                final canonicalHeadId =
                    await currentEventIdGetterSetters.canonicalHead.get();
                final canonicalHead =
                    await dataStores.headers.getOrRaise(canonicalHeadId);
                log.info(
                    "Canonical head id=${canonicalHeadId.show} height=${canonicalHead.height} slot=${canonicalHead.slot}");
              }))
                  .evalMap((_) => IO.fromFutureF(
                      currentEventIdGetterSetters.blockHeightTree.get))
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
                        .flatTap((consensus) =>
                            blockHeightTree.followChain(consensus.localChain))
                        .flatMap(
                          (consensus) => Ledger.make(
                                  dataStores,
                                  currentEventIdGetterSetters,
                                  parentChildTree,
                                  clock,
                                  consensus.localChain)
                              .map((ledger) => BlockchainCore(
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

  Future<void> validateBlock(FullBlock fullBlock) async {
    final id = fullBlock.header.id;
    log.info("Validating id=${id.show}");

    await log.timedInfoAsync(() async {
      await parentChildTree.assocate(id, fullBlock.header.parentHeaderId);
      await dataStores.headers.put(id, fullBlock.header);
      final errors =
          await consensus.blockHeaderValidation.validate(fullBlock.header);
      if (errors.isNotEmpty) {
        await dataStores.headers.remove(id);
        // TODO: Parent Child Tree Disassociate
        throw Exception("Invalid block. reason=$errors");
      }

      await validateBlockBody(fullBlock);
    }, messageF: (duration) => "Full block validation took $duration");
  }

  Future<void> validateBlockBody(FullBlock fullBlock) async {
    final id = fullBlock.header.id;
    final body = BlockBody(
        transactionIds: fullBlock.fullBody.transactions.map((t) => t.id));
    final block = Block(header: fullBlock.header, body: body);
    throwErrors(Future<List<String>> f) async {
      final errors = await f;
      if (errors.isNotEmpty) {
        // TODO: ParentChildTree disassociate
        await dataStores.headers.remove(id);
        await dataStores.bodies.remove(id);
        throw Exception("Invalid block. reason=$errors");
      }
    }

    await throwErrors(ledger.headerToBodyValidation.validate(block));

    for (final tx in fullBlock.fullBody.transactions) {
      await dataStores.transactions.put(tx.id, tx);
    }
    final validationContext = TransactionValidationContext(
        block.header.parentHeaderId, block.header.height, block.header.slot);

    await throwErrors(
        ledger.bodyValidation.validate(block.body, validationContext));
    await dataStores.bodies.put(id, body);
  }

  Future<void> processTransaction(Transaction transaction) async {
    final validationErrors =
        ledger.transactionSyntaxValidation.validate(transaction);
    if (validationErrors.isNotEmpty)
      throw ArgumentError.value(transaction, validationErrors.first);
    await dataStores.transactions.put(transaction.id, transaction);
    await ledger.mempool.add(transaction);
  }
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
          .flatMap((_) => Resource.eval(IO.fromFutureF(() async {
                log.info("Preparing P2P Network");

                late Ed25519KeyPair p2pKey;
                final maybeSk = await blockchain.dataStores.metadata
                    .get(MetadataIndices.p2pSk);
                if (maybeSk != null) {
                  final vk = await ed25519.getVerificationKey(maybeSk);
                  p2pKey = Ed25519KeyPair(maybeSk, vk);
                } else {
                  p2pKey = await ed25519.generateKeyPair();
                  await blockchain.dataStores.metadata
                      .put(MetadataIndices.p2pSk, p2pKey.sk);
                }
                final localPeerId = PeerId(value: p2pKey.vk.base58);
                log.info(
                    "Local peer id=${localPeerId.show} publicHost=${config.p2p.publicHost} publicPort=${config.p2p.publicPort}");
                final localPeer = ConnectedPeer(
                  peerId: localPeerId,
                  host: config.p2p.publicHost.stringValue,
                  port: config.p2p.publicPort.uint32Value,
                );
                void Function(String, int) connect = (_, __) {};
                final socketHandlerResource = (Socket socket) {
                  final shown = socket.show;
                  return Resource.pure(socket)
                      .onFinalize((socket) => IO.delay(() {
                            log.info("Disconnecting $shown");
                            socket.destroy();
                            return unit;
                          }))
                      .tapLog(log, (socket) => "Connected $shown");
                };
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
                              .use((socket) => IO.fromFutureF(
                                    () => peersManager
                                        .handleConnection(socket)
                                        .onError((e, stacktrace) => log.warning(
                                            "P2P Connection Error",
                                            e,
                                            stacktrace)),
                                  ))
                              .unsafeRunAndForget(),
                        ))
                    .tap((server) => connect = server.connectOutbound);
              })))
          .flatMap(identity)
          .flatMap(
            (p2pServer) => p2pServer.start().tap((_) => config.p2p.knownPeers
                .map((s) => s.split(":"))
                .forEach((parsed) => p2pServer
                    .connectOutbound(parsed[0], int.parse(parsed[1]))
                    .ignore())),
          )
          .map((backgroundHandler) => backgroundHandler.done)
          .tapLog(
              log,
              (_) =>
                  "Served on host=${config.p2p.bindHost} port=${config.p2p.bindPort}")
          .tapLogFinalize(log, "Terminating");
}

class BlockchainViewFromBlockchain extends BlockchainView {
  final BlockchainCore blockchain;

  BlockchainViewFromBlockchain({required this.blockchain});

  @override
  Stream<BlockId> get adoptions => blockchain.consensus.localChain.adoptions;

  @override
  Future<BlockId> get canonicalHeadId =>
      blockchain.consensus.localChain.currentHead;

  @override
  Future<BlockId> get genesisBlockId =>
      Future.value(blockchain.consensus.localChain.genesis);

  @override
  Future<BlockBody?> getBlockBody(BlockId blockId) =>
      blockchain.dataStores.bodies.get(blockId);

  @override
  Future<BlockHeader?> getBlockHeader(BlockId blockId) =>
      blockchain.dataStores.headers.get(blockId);

  @override
  Future<BlockId?> getBlockIdAtHeight(Int64 height) =>
      blockchain.consensus.localChain.blockIdAtHeight(height);

  @override
  Future<Transaction?> getTransaction(TransactionId transactionId) =>
      blockchain.dataStores.transactions.get(transactionId);

  @override
  Stream<TraversalStep> get traversal =>
      blockchain.consensus.localChain.traversal;

  @override
  Future<List<TransactionOutputReference>> getLockAddressState(
      LockAddress lock) {
    // TODO: implement getLockAddressState
    throw UnimplementedError();
  }

  @override
  Future<TransactionOutput?> getTransactionOutput(
      TransactionOutputReference reference) {
    // TODO: implement getTransactionOutput
    throw UnimplementedError();
  }
}
