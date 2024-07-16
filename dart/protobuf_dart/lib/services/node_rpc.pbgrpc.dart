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

import 'node_rpc.pb.dart' as $0;

export 'node_rpc.pb.dart';

@$pb.GrpcServiceName('blockchain.services.NodeRpc')
class NodeRpcClient extends $grpc.Client {
  static final _$broadcastTransaction = $grpc.ClientMethod<$0.BroadcastTransactionReq, $0.BroadcastTransactionRes>(
      '/blockchain.services.NodeRpc/BroadcastTransaction',
      ($0.BroadcastTransactionReq value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.BroadcastTransactionRes.fromBuffer(value));
  static final _$getBlockHeader = $grpc.ClientMethod<$0.GetBlockHeaderReq, $0.GetBlockHeaderRes>(
      '/blockchain.services.NodeRpc/GetBlockHeader',
      ($0.GetBlockHeaderReq value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.GetBlockHeaderRes.fromBuffer(value));
  static final _$getBlockBody = $grpc.ClientMethod<$0.GetBlockBodyReq, $0.GetBlockBodyRes>(
      '/blockchain.services.NodeRpc/GetBlockBody',
      ($0.GetBlockBodyReq value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.GetBlockBodyRes.fromBuffer(value));
  static final _$getFullBlock = $grpc.ClientMethod<$0.GetFullBlockReq, $0.GetFullBlockRes>(
      '/blockchain.services.NodeRpc/GetFullBlock',
      ($0.GetFullBlockReq value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.GetFullBlockRes.fromBuffer(value));
  static final _$getTransaction = $grpc.ClientMethod<$0.GetTransactionReq, $0.GetTransactionRes>(
      '/blockchain.services.NodeRpc/GetTransaction',
      ($0.GetTransactionReq value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.GetTransactionRes.fromBuffer(value));
  static final _$getBlockIdAtHeight = $grpc.ClientMethod<$0.GetBlockIdAtHeightReq, $0.GetBlockIdAtHeightRes>(
      '/blockchain.services.NodeRpc/GetBlockIdAtHeight',
      ($0.GetBlockIdAtHeightReq value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.GetBlockIdAtHeightRes.fromBuffer(value));
  static final _$follow = $grpc.ClientMethod<$0.FollowReq, $0.FollowRes>(
      '/blockchain.services.NodeRpc/Follow',
      ($0.FollowReq value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.FollowRes.fromBuffer(value));

  NodeRpcClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options,
        interceptors: interceptors);

  $grpc.ResponseFuture<$0.BroadcastTransactionRes> broadcastTransaction($0.BroadcastTransactionReq request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$broadcastTransaction, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetBlockHeaderRes> getBlockHeader($0.GetBlockHeaderReq request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getBlockHeader, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetBlockBodyRes> getBlockBody($0.GetBlockBodyReq request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getBlockBody, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetFullBlockRes> getFullBlock($0.GetFullBlockReq request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getFullBlock, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetTransactionRes> getTransaction($0.GetTransactionReq request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getTransaction, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetBlockIdAtHeightRes> getBlockIdAtHeight($0.GetBlockIdAtHeightReq request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getBlockIdAtHeight, request, options: options);
  }

  $grpc.ResponseStream<$0.FollowRes> follow($0.FollowReq request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$follow, $async.Stream.fromIterable([request]), options: options);
  }
}

@$pb.GrpcServiceName('blockchain.services.NodeRpc')
abstract class NodeRpcServiceBase extends $grpc.Service {
  $core.String get $name => 'blockchain.services.NodeRpc';

  NodeRpcServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.BroadcastTransactionReq, $0.BroadcastTransactionRes>(
        'BroadcastTransaction',
        broadcastTransaction_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.BroadcastTransactionReq.fromBuffer(value),
        ($0.BroadcastTransactionRes value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetBlockHeaderReq, $0.GetBlockHeaderRes>(
        'GetBlockHeader',
        getBlockHeader_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetBlockHeaderReq.fromBuffer(value),
        ($0.GetBlockHeaderRes value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetBlockBodyReq, $0.GetBlockBodyRes>(
        'GetBlockBody',
        getBlockBody_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetBlockBodyReq.fromBuffer(value),
        ($0.GetBlockBodyRes value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetFullBlockReq, $0.GetFullBlockRes>(
        'GetFullBlock',
        getFullBlock_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetFullBlockReq.fromBuffer(value),
        ($0.GetFullBlockRes value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetTransactionReq, $0.GetTransactionRes>(
        'GetTransaction',
        getTransaction_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetTransactionReq.fromBuffer(value),
        ($0.GetTransactionRes value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetBlockIdAtHeightReq, $0.GetBlockIdAtHeightRes>(
        'GetBlockIdAtHeight',
        getBlockIdAtHeight_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetBlockIdAtHeightReq.fromBuffer(value),
        ($0.GetBlockIdAtHeightRes value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.FollowReq, $0.FollowRes>(
        'Follow',
        follow_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.FollowReq.fromBuffer(value),
        ($0.FollowRes value) => value.writeToBuffer()));
  }

  $async.Future<$0.BroadcastTransactionRes> broadcastTransaction_Pre($grpc.ServiceCall call, $async.Future<$0.BroadcastTransactionReq> request) async {
    return broadcastTransaction(call, await request);
  }

  $async.Future<$0.GetBlockHeaderRes> getBlockHeader_Pre($grpc.ServiceCall call, $async.Future<$0.GetBlockHeaderReq> request) async {
    return getBlockHeader(call, await request);
  }

  $async.Future<$0.GetBlockBodyRes> getBlockBody_Pre($grpc.ServiceCall call, $async.Future<$0.GetBlockBodyReq> request) async {
    return getBlockBody(call, await request);
  }

  $async.Future<$0.GetFullBlockRes> getFullBlock_Pre($grpc.ServiceCall call, $async.Future<$0.GetFullBlockReq> request) async {
    return getFullBlock(call, await request);
  }

  $async.Future<$0.GetTransactionRes> getTransaction_Pre($grpc.ServiceCall call, $async.Future<$0.GetTransactionReq> request) async {
    return getTransaction(call, await request);
  }

  $async.Future<$0.GetBlockIdAtHeightRes> getBlockIdAtHeight_Pre($grpc.ServiceCall call, $async.Future<$0.GetBlockIdAtHeightReq> request) async {
    return getBlockIdAtHeight(call, await request);
  }

  $async.Stream<$0.FollowRes> follow_Pre($grpc.ServiceCall call, $async.Future<$0.FollowReq> request) async* {
    yield* follow(call, await request);
  }

  $async.Future<$0.BroadcastTransactionRes> broadcastTransaction($grpc.ServiceCall call, $0.BroadcastTransactionReq request);
  $async.Future<$0.GetBlockHeaderRes> getBlockHeader($grpc.ServiceCall call, $0.GetBlockHeaderReq request);
  $async.Future<$0.GetBlockBodyRes> getBlockBody($grpc.ServiceCall call, $0.GetBlockBodyReq request);
  $async.Future<$0.GetFullBlockRes> getFullBlock($grpc.ServiceCall call, $0.GetFullBlockReq request);
  $async.Future<$0.GetTransactionRes> getTransaction($grpc.ServiceCall call, $0.GetTransactionReq request);
  $async.Future<$0.GetBlockIdAtHeightRes> getBlockIdAtHeight($grpc.ServiceCall call, $0.GetBlockIdAtHeightReq request);
  $async.Stream<$0.FollowRes> follow($grpc.ServiceCall call, $0.FollowReq request);
}
