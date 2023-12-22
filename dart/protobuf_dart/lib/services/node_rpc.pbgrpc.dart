//
//  Generated code. Do not modify.
//  source: services/node_rpc.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'node_rpc.pb.dart' as $1;

export 'node_rpc.pb.dart';

@$pb.GrpcServiceName('com.blockchain.services.NodeRpc')
class NodeRpcClient extends $grpc.Client {
  static final _$broadcastTransaction = $grpc.ClientMethod<$1.BroadcastTransactionReq, $1.BroadcastTransactionRes>(
      '/com.blockchain.services.NodeRpc/BroadcastTransaction',
      ($1.BroadcastTransactionReq value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.BroadcastTransactionRes.fromBuffer(value));
  static final _$getBlock = $grpc.ClientMethod<$1.GetBlockReq, $1.GetBlockRes>(
      '/com.blockchain.services.NodeRpc/GetBlock',
      ($1.GetBlockReq value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.GetBlockRes.fromBuffer(value));
  static final _$getTransaction = $grpc.ClientMethod<$1.GetTransactionReq, $1.GetTransactionRes>(
      '/com.blockchain.services.NodeRpc/GetTransaction',
      ($1.GetTransactionReq value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.GetTransactionRes.fromBuffer(value));
  static final _$blockIdGossip = $grpc.ClientMethod<$1.BlockIdGossipReq, $1.BlockIdGossipRes>(
      '/com.blockchain.services.NodeRpc/BlockIdGossip',
      ($1.BlockIdGossipReq value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.BlockIdGossipRes.fromBuffer(value));

  NodeRpcClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options,
        interceptors: interceptors);

  $grpc.ResponseFuture<$1.BroadcastTransactionRes> broadcastTransaction($1.BroadcastTransactionReq request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$broadcastTransaction, request, options: options);
  }

  $grpc.ResponseFuture<$1.GetBlockRes> getBlock($1.GetBlockReq request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getBlock, request, options: options);
  }

  $grpc.ResponseFuture<$1.GetTransactionRes> getTransaction($1.GetTransactionReq request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getTransaction, request, options: options);
  }

  $grpc.ResponseStream<$1.BlockIdGossipRes> blockIdGossip($1.BlockIdGossipReq request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$blockIdGossip, $async.Stream.fromIterable([request]), options: options);
  }
}

@$pb.GrpcServiceName('com.blockchain.services.NodeRpc')
abstract class NodeRpcServiceBase extends $grpc.Service {
  $core.String get $name => 'com.blockchain.services.NodeRpc';

  NodeRpcServiceBase() {
    $addMethod($grpc.ServiceMethod<$1.BroadcastTransactionReq, $1.BroadcastTransactionRes>(
        'BroadcastTransaction',
        broadcastTransaction_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.BroadcastTransactionReq.fromBuffer(value),
        ($1.BroadcastTransactionRes value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.GetBlockReq, $1.GetBlockRes>(
        'GetBlock',
        getBlock_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.GetBlockReq.fromBuffer(value),
        ($1.GetBlockRes value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.GetTransactionReq, $1.GetTransactionRes>(
        'GetTransaction',
        getTransaction_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.GetTransactionReq.fromBuffer(value),
        ($1.GetTransactionRes value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.BlockIdGossipReq, $1.BlockIdGossipRes>(
        'BlockIdGossip',
        blockIdGossip_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $1.BlockIdGossipReq.fromBuffer(value),
        ($1.BlockIdGossipRes value) => value.writeToBuffer()));
  }

  $async.Future<$1.BroadcastTransactionRes> broadcastTransaction_Pre($grpc.ServiceCall call, $async.Future<$1.BroadcastTransactionReq> request) async {
    return broadcastTransaction(call, await request);
  }

  $async.Future<$1.GetBlockRes> getBlock_Pre($grpc.ServiceCall call, $async.Future<$1.GetBlockReq> request) async {
    return getBlock(call, await request);
  }

  $async.Future<$1.GetTransactionRes> getTransaction_Pre($grpc.ServiceCall call, $async.Future<$1.GetTransactionReq> request) async {
    return getTransaction(call, await request);
  }

  $async.Stream<$1.BlockIdGossipRes> blockIdGossip_Pre($grpc.ServiceCall call, $async.Future<$1.BlockIdGossipReq> request) async* {
    yield* blockIdGossip(call, await request);
  }

  $async.Future<$1.BroadcastTransactionRes> broadcastTransaction($grpc.ServiceCall call, $1.BroadcastTransactionReq request);
  $async.Future<$1.GetBlockRes> getBlock($grpc.ServiceCall call, $1.GetBlockReq request);
  $async.Future<$1.GetTransactionRes> getTransaction($grpc.ServiceCall call, $1.GetTransactionReq request);
  $async.Stream<$1.BlockIdGossipRes> blockIdGossip($grpc.ServiceCall call, $1.BlockIdGossipReq request);
}
