import 'package:blockchain/common/resource.dart';
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
  final Stream<BlockId> _localAdoptions;
  final Future<Block?> Function(BlockId) _getBlock;
  final Future<Transaction?> Function(TransactionId) _getTransaction;
  final Future<void> Function(Transaction) _onBroadcastTransaction;

  NodeRpcServiceImpl(
      {required Stream<BlockId> localAdoptions,
      required Future<Block?> Function(BlockId) getBlock,
      required Future<Transaction?> Function(TransactionId) getTransaction,
      required Future<void> Function(Transaction) onBroadcastTransaction})
      : _localAdoptions = localAdoptions,
        _getBlock = getBlock,
        _getTransaction = getTransaction,
        _onBroadcastTransaction = onBroadcastTransaction;

  @override
  Stream<BlockIdGossipRes> blockIdGossip(
      ServiceCall call, BlockIdGossipReq request) {
    return _localAdoptions.map((id) => BlockIdGossipRes(blockId: id));
  }

  @override
  Future<BroadcastTransactionRes> broadcastTransaction(
      ServiceCall call, BroadcastTransactionReq request) async {
    assert(request.hasTransaction());
    await _onBroadcastTransaction(request.transaction);
    return BroadcastTransactionRes();
  }

  @override
  Future<GetBlockRes> getBlock(ServiceCall call, GetBlockReq request) async {
    assert(request.hasBlockId());
    final block = await _getBlock(request.blockId);
    return GetBlockRes(block: block);
  }

  @override
  Future<GetTransactionRes> getTransaction(
      ServiceCall call, GetTransactionReq request) async {
    assert(request.hasTransactionId());
    final transaction = await _getTransaction(request.transactionId);
    return GetTransactionRes(transaction: transaction);
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
