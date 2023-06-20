import 'dart:async';

import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_protobuf/services/node_rpc.pbgrpc.dart';
import 'package:grpc/src/server/call.dart';

class RpcServer extends NodeRpcServiceBase {
  final Stream<BlockId> Function() _blockIdGossip;
  final Stream<TransactionId> Function() _transactionIdGossip;
  final Future<Block?> Function(BlockId) _fetchBlock;
  final Future<Transaction?> Function(TransactionId) _fetchTransaction;
  final Future<void> Function(Transaction) _processTransaction;

  RpcServer(
    this._blockIdGossip,
    this._transactionIdGossip,
    this._fetchBlock,
    this._fetchTransaction,
    this._processTransaction,
  );

  @override
  Stream<BlockIdGossipRes> blockIdGossip(
      ServiceCall call, BlockIdGossipReq request) {
    return _blockIdGossip().map((id) => BlockIdGossipRes()..blockId = id);
  }

  @override
  Future<BroadcastTransactionRes> broadcastTransaction(
      ServiceCall call, BroadcastTransactionReq request) async {
    await _processTransaction(request.transaction);
    return BroadcastTransactionRes();
  }

  @override
  Future<GetBlockRes> getBlock(ServiceCall call, GetBlockReq request) async {
    final maybeBlock = await _fetchBlock(request.blockId);
    if (maybeBlock != null) return GetBlockRes()..block = maybeBlock;
    return GetBlockRes();
  }

  @override
  Future<GetTransactionRes> getTransaction(
      ServiceCall call, GetTransactionReq request) async {
    final maybeTransaction = await _fetchTransaction(request.transactionId);
    if (maybeTransaction != null)
      return GetTransactionRes()..transaction = maybeTransaction;
    return GetTransactionRes();
  }

  @override
  Stream<TransactionIdGossipRes> transactionIdGossip(
          ServiceCall call, TransactionIdGossipReq request) =>
      _transactionIdGossip()
          .map((id) => TransactionIdGossipRes()..transactionId = id);

  @override
  Future<HandshakeRes> handshake(ServiceCall call, HandshakeReq request) {
    return Future.value(HandshakeRes());
  }
}
