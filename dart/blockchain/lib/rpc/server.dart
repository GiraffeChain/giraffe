import 'package:blockchain/common/resource.dart';
import 'package:blockchain/data_stores.dart';
import 'package:blockchain/traversal.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_protobuf/services/node_rpc.pbgrpc.dart';
import 'package:blockchain_protobuf/services/staker_support_rpc.pbgrpc.dart';
import 'package:grpc/grpc.dart';
import 'package:fixnum/fixnum.dart';

Resource<Server> serveRpcs(String host, int port, NodeRpcServiceBase nodeRpc,
        StakerSupportRpcServiceBase stakerSupportRpc) =>
    Resource.pure(Server.create(services: [nodeRpc, stakerSupportRpc]))
        .evalTap((server) => server.serve(address: host, port: port));

class NodeRpcServiceImpl extends NodeRpcServiceBase {
  final Stream<TraversalStep> _traversal;
  final DataStores _dataStores;
  final Future<void> Function(Transaction) _onBroadcastTransaction;
  final Future<BlockId?> Function(Int64) _blockIdAtHeight;

  NodeRpcServiceImpl(
      {required Stream<TraversalStep> traversal,
      required DataStores dataStores,
      required Future<void> Function(Transaction) onBroadcastTransaction,
      required Future<BlockId?> Function(Int64) blockIdAtHeight})
      : _traversal = traversal,
        _dataStores = dataStores,
        _onBroadcastTransaction = onBroadcastTransaction,
        _blockIdAtHeight = blockIdAtHeight;

  @override
  Stream<FollowRes> follow(ServiceCall call, FollowReq request) {
    return _traversal.map((t) {
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
    await _onBroadcastTransaction(request.transaction);
    return BroadcastTransactionRes();
  }

  @override
  Future<GetFullBlockRes> getFullBlock(
      ServiceCall call, GetFullBlockReq request) async {
    assert(request.hasBlockId());
    final block = await _dataStores.getFullBlock(request.blockId);
    return GetFullBlockRes(fullBlock: block);
  }

  @override
  Future<GetTransactionRes> getTransaction(
      ServiceCall call, GetTransactionReq request) async {
    assert(request.hasTransactionId());
    final transaction =
        await _dataStores.transactions.get(request.transactionId);
    return GetTransactionRes(transaction: transaction);
  }

  @override
  Future<GetBlockBodyRes> getBlockBody(
      ServiceCall call, GetBlockBodyReq request) async {
    assert(request.hasBlockId());
    final body = await _dataStores.bodies.get(request.blockId);
    return GetBlockBodyRes(body: body);
  }

  @override
  Future<GetBlockHeaderRes> getBlockHeader(
      ServiceCall call, GetBlockHeaderReq request) async {
    assert(request.hasBlockId());
    final header = await _dataStores.headers.get(request.blockId);
    return GetBlockHeaderRes(header: header);
  }

  @override
  Future<GetBlockIdAtHeightRes> getBlockIdAtHeight(
      ServiceCall call, GetBlockIdAtHeightReq request) async {
    final blockId = await _blockIdAtHeight(request.height);
    return GetBlockIdAtHeightRes(blockId: blockId);
  }
}

class StakerSupportRpcImpl extends StakerSupportRpcServiceBase {
  final Future<void> Function(Block) _onBroadcastBlock;
  final Future<ActiveStaker?> Function(StakingAddress, BlockId, Int64)
      _getStaker;
  final Stream<BlockBody> Function(BlockId, Int64) _packBlock;

  StakerSupportRpcImpl(
      {required Future<void> Function(Block) onBroadcastBlock,
      required Future<ActiveStaker?> Function(StakingAddress, BlockId, Int64)
          getStaker,
      required Stream<BlockBody> Function(BlockId, Int64) packBlock})
      : _onBroadcastBlock = onBroadcastBlock,
        _getStaker = getStaker,
        _packBlock = packBlock;

  @override
  Future<BroadcastBlockRes> broadcastBlock(
      ServiceCall call, BroadcastBlockReq request) async {
    assert(request.hasBlock());
    await _onBroadcastBlock(request.block);
    return BroadcastBlockRes();
  }

  @override
  Future<GetStakerRes> getStaker(ServiceCall call, GetStakerReq request) async {
    assert(request.hasParentBlockId());
    assert(request.hasStakingAddress());
    assert(request.hasSlot());
    final staker = await _getStaker(
        request.stakingAddress, request.parentBlockId, request.slot);
    return GetStakerRes(staker: staker);
  }

  @override
  Stream<PackBlockRes> packBlock(
      ServiceCall call, PackBlockReq request) async* {
    assert(request.hasParentBlockId());
    assert(request.hasUntilSlot());
    await for (final candidate
        in _packBlock(request.parentBlockId, request.untilSlot)) {
      yield PackBlockRes(body: candidate);
    }
  }
}
