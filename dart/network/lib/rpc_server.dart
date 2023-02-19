import 'dart:async';

import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_protobuf/services/node_rpc.pbgrpc.dart';
import 'package:grpc/src/server/call.dart';

class RpcServer extends NodeRpcServiceBase {
  final Stream<BlockId> Function() _localAdoptions;
  final Future<Block?> Function(BlockId) _fetchBlock;

  RpcServer(this._localAdoptions, this._fetchBlock);
  @override
  Stream<BlockIdGossipRes> blockIdGossip(
      ServiceCall call, BlockIdGossipReq request) {
    return _localAdoptions().map((id) => BlockIdGossipRes(blockId: id));
  }

  @override
  Future<BroadcastTransactionRes> broadcastTransaction(
      ServiceCall call, BroadcastTransactionReq request) {
    // TODO: implement broadcastTransaction
    throw UnimplementedError();
  }

  @override
  Future<GetBlockRes> getBlock(ServiceCall call, GetBlockReq request) async {
    final maybeBlock = await _fetchBlock(request.blockId);
    return GetBlockRes(block: maybeBlock);
  }

  @override
  Future<GetTransactionRes> getTransaction(
      ServiceCall call, GetTransactionReq request) {
    // TODO: implement getTransaction
    throw UnimplementedError();
  }

  @override
  Stream<TransactionIdGossipRes> transactionIdGossip(
      ServiceCall call, TransactionIdGossipReq request) {
    // TODO: implement transactionIdGossip
    throw UnimplementedError();
  }

  @override
  Future<HandshakeRes> handshake(ServiceCall call, HandshakeReq request) {
    return Future.value(HandshakeRes());
  }
}
