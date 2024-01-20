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

@$pb.GrpcServiceName('blockchain.services.NodeRpc')
class NodeRpcClient extends $grpc.Client {
  static final _$broadcastTransaction = $grpc.ClientMethod<$1.BroadcastTransactionReq, $1.BroadcastTransactionRes>(
      '/blockchain.services.NodeRpc/BroadcastTransaction',
      ($1.BroadcastTransactionReq value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.BroadcastTransactionRes.fromBuffer(value));
  static final _$getBlockHeader = $grpc.ClientMethod<$1.GetBlockHeaderReq, $1.GetBlockHeaderRes>(
      '/blockchain.services.NodeRpc/GetBlockHeader',
      ($1.GetBlockHeaderReq value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.GetBlockHeaderRes.fromBuffer(value));
  static final _$getBlockBody = $grpc.ClientMethod<$1.GetBlockBodyReq, $1.GetBlockBodyRes>(
      '/blockchain.services.NodeRpc/GetBlockBody',
      ($1.GetBlockBodyReq value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.GetBlockBodyRes.fromBuffer(value));
  static final _$getFullBlock = $grpc.ClientMethod<$1.GetFullBlockReq, $1.GetFullBlockRes>(
      '/blockchain.services.NodeRpc/GetFullBlock',
      ($1.GetFullBlockReq value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.GetFullBlockRes.fromBuffer(value));
  static final _$getTransaction = $grpc.ClientMethod<$1.GetTransactionReq, $1.GetTransactionRes>(
      '/blockchain.services.NodeRpc/GetTransaction',
      ($1.GetTransactionReq value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.GetTransactionRes.fromBuffer(value));
  static final _$getBlockIdAtHeight = $grpc.ClientMethod<$1.GetBlockIdAtHeightReq, $1.GetBlockIdAtHeightRes>(
      '/blockchain.services.NodeRpc/GetBlockIdAtHeight',
      ($1.GetBlockIdAtHeightReq value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.GetBlockIdAtHeightRes.fromBuffer(value));
  static final _$follow = $grpc.ClientMethod<$1.FollowReq, $1.FollowRes>(
      '/blockchain.services.NodeRpc/Follow',
      ($1.FollowReq value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.FollowRes.fromBuffer(value));

  NodeRpcClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options,
        interceptors: interceptors);

  $grpc.ResponseFuture<$1.BroadcastTransactionRes> broadcastTransaction($1.BroadcastTransactionReq request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$broadcastTransaction, request, options: options);
  }

  $grpc.ResponseFuture<$1.GetBlockHeaderRes> getBlockHeader($1.GetBlockHeaderReq request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getBlockHeader, request, options: options);
  }

  $grpc.ResponseFuture<$1.GetBlockBodyRes> getBlockBody($1.GetBlockBodyReq request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getBlockBody, request, options: options);
  }

  $grpc.ResponseFuture<$1.GetFullBlockRes> getFullBlock($1.GetFullBlockReq request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getFullBlock, request, options: options);
  }

  $grpc.ResponseFuture<$1.GetTransactionRes> getTransaction($1.GetTransactionReq request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getTransaction, request, options: options);
  }

  $grpc.ResponseFuture<$1.GetBlockIdAtHeightRes> getBlockIdAtHeight($1.GetBlockIdAtHeightReq request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getBlockIdAtHeight, request, options: options);
  }

  $grpc.ResponseStream<$1.FollowRes> follow($1.FollowReq request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$follow, $async.Stream.fromIterable([request]), options: options);
  }
}

@$pb.GrpcServiceName('blockchain.services.NodeRpc')
abstract class NodeRpcServiceBase extends $grpc.Service {
  $core.String get $name => 'blockchain.services.NodeRpc';

  NodeRpcServiceBase() {
    $addMethod($grpc.ServiceMethod<$1.BroadcastTransactionReq, $1.BroadcastTransactionRes>(
        'BroadcastTransaction',
        broadcastTransaction_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.BroadcastTransactionReq.fromBuffer(value),
        ($1.BroadcastTransactionRes value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.GetBlockHeaderReq, $1.GetBlockHeaderRes>(
        'GetBlockHeader',
        getBlockHeader_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.GetBlockHeaderReq.fromBuffer(value),
        ($1.GetBlockHeaderRes value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.GetBlockBodyReq, $1.GetBlockBodyRes>(
        'GetBlockBody',
        getBlockBody_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.GetBlockBodyReq.fromBuffer(value),
        ($1.GetBlockBodyRes value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.GetFullBlockReq, $1.GetFullBlockRes>(
        'GetFullBlock',
        getFullBlock_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.GetFullBlockReq.fromBuffer(value),
        ($1.GetFullBlockRes value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.GetTransactionReq, $1.GetTransactionRes>(
        'GetTransaction',
        getTransaction_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.GetTransactionReq.fromBuffer(value),
        ($1.GetTransactionRes value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.GetBlockIdAtHeightReq, $1.GetBlockIdAtHeightRes>(
        'GetBlockIdAtHeight',
        getBlockIdAtHeight_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.GetBlockIdAtHeightReq.fromBuffer(value),
        ($1.GetBlockIdAtHeightRes value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.FollowReq, $1.FollowRes>(
        'Follow',
        follow_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $1.FollowReq.fromBuffer(value),
        ($1.FollowRes value) => value.writeToBuffer()));
  }

  $async.Future<$1.BroadcastTransactionRes> broadcastTransaction_Pre($grpc.ServiceCall call, $async.Future<$1.BroadcastTransactionReq> request) async {
    return broadcastTransaction(call, await request);
  }

  $async.Future<$1.GetBlockHeaderRes> getBlockHeader_Pre($grpc.ServiceCall call, $async.Future<$1.GetBlockHeaderReq> request) async {
    return getBlockHeader(call, await request);
  }

  $async.Future<$1.GetBlockBodyRes> getBlockBody_Pre($grpc.ServiceCall call, $async.Future<$1.GetBlockBodyReq> request) async {
    return getBlockBody(call, await request);
  }

  $async.Future<$1.GetFullBlockRes> getFullBlock_Pre($grpc.ServiceCall call, $async.Future<$1.GetFullBlockReq> request) async {
    return getFullBlock(call, await request);
  }

  $async.Future<$1.GetTransactionRes> getTransaction_Pre($grpc.ServiceCall call, $async.Future<$1.GetTransactionReq> request) async {
    return getTransaction(call, await request);
  }

  $async.Future<$1.GetBlockIdAtHeightRes> getBlockIdAtHeight_Pre($grpc.ServiceCall call, $async.Future<$1.GetBlockIdAtHeightReq> request) async {
    return getBlockIdAtHeight(call, await request);
  }

  $async.Stream<$1.FollowRes> follow_Pre($grpc.ServiceCall call, $async.Future<$1.FollowReq> request) async* {
    yield* follow(call, await request);
  }

  $async.Future<$1.BroadcastTransactionRes> broadcastTransaction($grpc.ServiceCall call, $1.BroadcastTransactionReq request);
  $async.Future<$1.GetBlockHeaderRes> getBlockHeader($grpc.ServiceCall call, $1.GetBlockHeaderReq request);
  $async.Future<$1.GetBlockBodyRes> getBlockBody($grpc.ServiceCall call, $1.GetBlockBodyReq request);
  $async.Future<$1.GetFullBlockRes> getFullBlock($grpc.ServiceCall call, $1.GetFullBlockReq request);
  $async.Future<$1.GetTransactionRes> getTransaction($grpc.ServiceCall call, $1.GetTransactionReq request);
  $async.Future<$1.GetBlockIdAtHeightRes> getBlockIdAtHeight($grpc.ServiceCall call, $1.GetBlockIdAtHeightReq request);
  $async.Stream<$1.FollowRes> follow($grpc.ServiceCall call, $1.FollowReq request);
}
