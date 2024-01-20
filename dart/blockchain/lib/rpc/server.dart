import 'package:blockchain/blockchain.dart';
import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain/common/utils.dart';
import 'package:blockchain/traversal.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_protobuf/services/node_rpc.pbgrpc.dart';
import 'package:blockchain_protobuf/services/staker_support_rpc.pbgrpc.dart';
import 'package:grpc/grpc.dart';
import 'package:logging/logging.dart';

Resource<Server> serveRpcs(String host, int port, NodeRpcServiceBase nodeRpc,
        StakerSupportRpcServiceBase stakerSupportRpc) =>
    Resource.pure(Server.create(services: [nodeRpc, stakerSupportRpc]))
        .evalTap((server) => server.serve(address: host, port: port));

class NodeRpcServiceImpl extends NodeRpcServiceBase {
  final BlockchainCore blockchain;

  NodeRpcServiceImpl({required this.blockchain});

  final log = Logger("Blockchain.RPC");

  @override
  Stream<FollowRes> follow(ServiceCall call, FollowReq request) {
    return blockchain.consensus.localChain.traversal.map((t) {
      if (t is TraversalStep_Applied) {
        return FollowRes(adopted: t.blockId);
      } else if (t is TraversalStep_Unapplied) {
        return FollowRes(unadopted: t.blockId);
      } else
        throw ArgumentError.notNull();
    });
  }

  @override
  Future<BroadcastTransactionRes> broadcastTransaction(
      ServiceCall call, BroadcastTransactionReq request) async {
    assert(request.hasTransaction());
    request.transaction.embedId();
    log.info("Received transaction id=${request.transaction.id.show}");
    await blockchain.processTransaction(request.transaction);
    return BroadcastTransactionRes();
  }

  @override
  Future<GetFullBlockRes> getFullBlock(
      ServiceCall call, GetFullBlockReq request) async {
    assert(request.hasBlockId());
    final block = await blockchain.dataStores.getFullBlock(request.blockId);
    return GetFullBlockRes(fullBlock: block);
  }

  @override
  Future<GetTransactionRes> getTransaction(
      ServiceCall call, GetTransactionReq request) async {
    assert(request.hasTransactionId());
    final transaction =
        await blockchain.dataStores.transactions.get(request.transactionId);
    return GetTransactionRes(transaction: transaction);
  }

  @override
  Future<GetBlockBodyRes> getBlockBody(
      ServiceCall call, GetBlockBodyReq request) async {
    assert(request.hasBlockId());
    final body = await blockchain.dataStores.bodies.get(request.blockId);
    return GetBlockBodyRes(body: body);
  }

  @override
  Future<GetBlockHeaderRes> getBlockHeader(
      ServiceCall call, GetBlockHeaderReq request) async {
    assert(request.hasBlockId());
    final header = await blockchain.dataStores.headers.get(request.blockId);
    return GetBlockHeaderRes(header: header);
  }

  @override
  Future<GetBlockIdAtHeightRes> getBlockIdAtHeight(
      ServiceCall call, GetBlockIdAtHeightReq request) async {
    final blockId =
        await blockchain.consensus.localChain.blockIdAtHeight(request.height);
    return GetBlockIdAtHeightRes(blockId: blockId);
  }
}

class StakerSupportRpcImpl extends StakerSupportRpcServiceBase {
  final BlockchainCore blockchain;

  StakerSupportRpcImpl({required this.blockchain});

  final log = Logger("Blockchain.RPC");

  @override
  Future<BroadcastBlockRes> broadcastBlock(
      ServiceCall call, BroadcastBlockReq request) async {
    assert(request.hasBlock());
    final block = request.block;
    block.header.embedId();
    log.info("Received block id=${block.header.id.show}");
    final currentHeadId = await blockchain.consensus.localChain.currentHead;
    final currentHead =
        await blockchain.dataStores.headers.getOrRaise(currentHeadId);
    if (block.header.height == currentHead.height)
      assert(block.header.parentHeaderId == currentHead.parentHeaderId);
    else {
      assert(block.header.parentHeaderId == currentHeadId);
    }
    final selectedId = (await blockchain.consensus.chainSelection
            .maxValidBg(currentHead, block.header))
        .id;
    assert(selectedId == block.header.id);
    final fullBlockBody = FullBlockBody(
        transactions: await Future.wait(block.body.transactionIds
            .map(blockchain.dataStores.transactions.getOrRaise)
            .toList()));
    final fullBlock = FullBlock(header: block.header, fullBody: fullBlockBody);
    await blockchain.validateBlock(fullBlock);
    await blockchain.consensus.localChain.adopt(block.header.id);
    return BroadcastBlockRes();
  }

  @override
  Future<GetStakerRes> getStaker(ServiceCall call, GetStakerReq request) async {
    assert(request.hasParentBlockId());
    assert(request.hasStakingAccount());
    assert(request.hasSlot());
    final staker = await blockchain.consensus.stakerTracker.staker(
      request.parentBlockId,
      request.slot,
      request.stakingAccount,
    );
    return GetStakerRes(staker: staker);
  }

  @override
  Stream<PackBlockRes> packBlock(ServiceCall call, PackBlockReq request) {
    assert(request.hasParentBlockId());
    assert(request.hasUntilSlot());
    return Stream.fromFuture(
            blockchain.dataStores.headers.getOrRaise(request.parentBlockId))
        .map((h) => h.height)
        .asyncExpand((parentHeight) => blockchain.ledger.blockPacker
            .streamed(
                request.parentBlockId, parentHeight + 1, request.untilSlot)
            .map((fullBody) => BlockBody(
                transactionIds: fullBody.transactions.map((t) => t.id))))
        .map((candidate) => PackBlockRes(body: candidate));
  }

  @override
  Future<CalculateEtaRes> calculateEta(
      ServiceCall call, CalculateEtaReq request) async {
    final parentHeader =
        await blockchain.dataStores.headers.getOrRaise(request.parentBlockId);
    final eta = await blockchain.consensus.etaCalculation
        .etaToBe(parentHeader.slotId, request.slot);
    return CalculateEtaRes(eta: eta);
  }

  @override
  Future<GetTotalActiveStakeRes> getTotalActivestake(
      ServiceCall call, GetTotalActiveStakeReq request) async {
    final totalActiveStake = await blockchain.consensus.stakerTracker
        .totalActiveStake(request.parentBlockId, request.slot);
    return GetTotalActiveStakeRes(totalActiveStake: totalActiveStake);
  }
}
