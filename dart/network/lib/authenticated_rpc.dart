import 'package:blockchain_protobuf/services/node_rpc.pbgrpc.dart' as $0;

import 'package:grpc/service_api.dart' as $grpc;

class AuthenticatedRpcClient extends $0.NodeRpcClient {
  final String localAddress;
  AuthenticatedRpcClient(super.channel, this.localAddress);

  $grpc.ResponseFuture<$0.BroadcastTransactionRes> broadcastTransaction(
          $0.BroadcastTransactionReq request,
          {$grpc.CallOptions? options}) =>
      super.broadcastTransaction(request, options: _modifyOptions(options));

  $grpc.ResponseFuture<$0.GetBlockRes> getBlock($0.GetBlockReq request,
          {$grpc.CallOptions? options}) =>
      super.getBlock(request, options: _modifyOptions(options));

  $grpc.ResponseFuture<$0.GetTransactionRes> getTransaction(
          $0.GetTransactionReq request,
          {$grpc.CallOptions? options}) =>
      super.getTransaction(request, options: _modifyOptions(options));

  $grpc.ResponseStream<$0.BlockIdGossipRes> blockIdGossip(
          $0.BlockIdGossipReq request,
          {$grpc.CallOptions? options}) =>
      super.blockIdGossip(request, options: _modifyOptions(options));

  $grpc.ResponseStream<$0.TransactionIdGossipRes> transactionIdGossip(
          $0.TransactionIdGossipReq request,
          {$grpc.CallOptions? options}) =>
      super.transactionIdGossip(request, options: _modifyOptions(options));

  _modifyOptions($grpc.CallOptions? options) =>
      $grpc.CallOptions(metadata: {"p2p-address": localAddress})
          .mergedWith(options);
}

class AuthenticatedGrpcServer extends $0.NodeRpcServiceBase {
  final $0.NodeRpcServiceBase delegate;
  final Set<String> knownPeerAddresses = Set();
  final void Function(String) peerConnected;

  AuthenticatedGrpcServer(this.delegate, this.peerConnected);

  @override
  Stream<$0.BlockIdGossipRes> blockIdGossip(
      $grpc.ServiceCall call, $0.BlockIdGossipReq request) {
    _verifyKnownId(call);
    return delegate.blockIdGossip(call, request);
  }

  @override
  Future<$0.BroadcastTransactionRes> broadcastTransaction(
      $grpc.ServiceCall call, $0.BroadcastTransactionReq request) async {
    _verifyKnownId(call);
    return await delegate.broadcastTransaction(call, request);
  }

  @override
  Future<$0.GetBlockRes> getBlock(
      $grpc.ServiceCall call, $0.GetBlockReq request) async {
    _verifyKnownId(call);
    return await delegate.getBlock(call, request);
  }

  @override
  Future<$0.GetTransactionRes> getTransaction(
      $grpc.ServiceCall call, $0.GetTransactionReq request) async {
    _verifyKnownId(call);
    return await delegate.getTransaction(call, request);
  }

  @override
  Future<$0.HandshakeRes> handshake(
      $grpc.ServiceCall call, $0.HandshakeReq request) async {
    knownPeerAddresses.add(request.p2pAddress);
    peerConnected(request.p2pAddress);
    return await delegate.handshake(call, request);
  }

  @override
  Stream<$0.TransactionIdGossipRes> transactionIdGossip(
      $grpc.ServiceCall call, $0.TransactionIdGossipReq request) {
    _verifyKnownId(call);
    return delegate.transactionIdGossip(call, request);
  }

  _verifyKnownId($grpc.ServiceCall call) {
    final p2pAddress = call.clientMetadata!["p2p-address"]!;
    if (!knownPeerAddresses.contains(p2pAddress)) {
      print("Received call from unknown peer with address=$p2pAddress");
      throw new ArgumentError("Unknown peer");
    }
  }
}
