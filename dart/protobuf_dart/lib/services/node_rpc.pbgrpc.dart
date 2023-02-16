///
//  Generated code. Do not modify.
//  source: services/node_rpc.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:async' as $async;

import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'node_rpc.pb.dart' as $0;
export 'node_rpc.pb.dart';

class NodeRpcClient extends $grpc.Client {
  static final _$broadcastTransaction = $grpc.ClientMethod<
          $0.BroadcastTransactionReq, $0.BroadcastTransactionRes>(
      '/com.blockchain.services.NodeRpc/BroadcastTransaction',
      ($0.BroadcastTransactionReq value) => value.writeToBuffer(),
      ($core.List<$core.int> value) =>
          $0.BroadcastTransactionRes.fromBuffer(value));
  static final _$getBlock = $grpc.ClientMethod<$0.GetBlockReq, $0.GetBlockRes>(
      '/com.blockchain.services.NodeRpc/GetBlock',
      ($0.GetBlockReq value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.GetBlockRes.fromBuffer(value));
  static final _$getTransaction =
      $grpc.ClientMethod<$0.GetTransactionReq, $0.GetTransactionRes>(
          '/com.blockchain.services.NodeRpc/GetTransaction',
          ($0.GetTransactionReq value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.GetTransactionRes.fromBuffer(value));
  static final _$blockIdGossip =
      $grpc.ClientMethod<$0.BlockIdGossipReq, $0.BlockIdGossipRes>(
          '/com.blockchain.services.NodeRpc/BlockIdGossip',
          ($0.BlockIdGossipReq value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.BlockIdGossipRes.fromBuffer(value));
  static final _$transactionIdGossip =
      $grpc.ClientMethod<$0.TransactionIdGossipReq, $0.TransactionIdGossipRes>(
          '/com.blockchain.services.NodeRpc/TransactionIdGossip',
          ($0.TransactionIdGossipReq value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.TransactionIdGossipRes.fromBuffer(value));

  NodeRpcClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$0.BroadcastTransactionRes> broadcastTransaction(
      $0.BroadcastTransactionReq request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$broadcastTransaction, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetBlockRes> getBlock($0.GetBlockReq request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getBlock, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetTransactionRes> getTransaction(
      $0.GetTransactionReq request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getTransaction, request, options: options);
  }

  $grpc.ResponseStream<$0.BlockIdGossipRes> blockIdGossip(
      $0.BlockIdGossipReq request,
      {$grpc.CallOptions? options}) {
    return $createStreamingCall(
        _$blockIdGossip, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseStream<$0.TransactionIdGossipRes> transactionIdGossip(
      $0.TransactionIdGossipReq request,
      {$grpc.CallOptions? options}) {
    return $createStreamingCall(
        _$transactionIdGossip, $async.Stream.fromIterable([request]),
        options: options);
  }
}

abstract class NodeRpcServiceBase extends $grpc.Service {
  $core.String get $name => 'com.blockchain.services.NodeRpc';

  NodeRpcServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.BroadcastTransactionReq,
            $0.BroadcastTransactionRes>(
        'BroadcastTransaction',
        broadcastTransaction_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.BroadcastTransactionReq.fromBuffer(value),
        ($0.BroadcastTransactionRes value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetBlockReq, $0.GetBlockRes>(
        'GetBlock',
        getBlock_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetBlockReq.fromBuffer(value),
        ($0.GetBlockRes value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetTransactionReq, $0.GetTransactionRes>(
        'GetTransaction',
        getTransaction_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetTransactionReq.fromBuffer(value),
        ($0.GetTransactionRes value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.BlockIdGossipReq, $0.BlockIdGossipRes>(
        'BlockIdGossip',
        blockIdGossip_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.BlockIdGossipReq.fromBuffer(value),
        ($0.BlockIdGossipRes value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.TransactionIdGossipReq,
            $0.TransactionIdGossipRes>(
        'TransactionIdGossip',
        transactionIdGossip_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.TransactionIdGossipReq.fromBuffer(value),
        ($0.TransactionIdGossipRes value) => value.writeToBuffer()));
  }

  $async.Future<$0.BroadcastTransactionRes> broadcastTransaction_Pre(
      $grpc.ServiceCall call,
      $async.Future<$0.BroadcastTransactionReq> request) async {
    return broadcastTransaction(call, await request);
  }

  $async.Future<$0.GetBlockRes> getBlock_Pre(
      $grpc.ServiceCall call, $async.Future<$0.GetBlockReq> request) async {
    return getBlock(call, await request);
  }

  $async.Future<$0.GetTransactionRes> getTransaction_Pre($grpc.ServiceCall call,
      $async.Future<$0.GetTransactionReq> request) async {
    return getTransaction(call, await request);
  }

  $async.Stream<$0.BlockIdGossipRes> blockIdGossip_Pre($grpc.ServiceCall call,
      $async.Future<$0.BlockIdGossipReq> request) async* {
    yield* blockIdGossip(call, await request);
  }

  $async.Stream<$0.TransactionIdGossipRes> transactionIdGossip_Pre(
      $grpc.ServiceCall call,
      $async.Future<$0.TransactionIdGossipReq> request) async* {
    yield* transactionIdGossip(call, await request);
  }

  $async.Future<$0.BroadcastTransactionRes> broadcastTransaction(
      $grpc.ServiceCall call, $0.BroadcastTransactionReq request);
  $async.Future<$0.GetBlockRes> getBlock(
      $grpc.ServiceCall call, $0.GetBlockReq request);
  $async.Future<$0.GetTransactionRes> getTransaction(
      $grpc.ServiceCall call, $0.GetTransactionReq request);
  $async.Stream<$0.BlockIdGossipRes> blockIdGossip(
      $grpc.ServiceCall call, $0.BlockIdGossipReq request);
  $async.Stream<$0.TransactionIdGossipRes> transactionIdGossip(
      $grpc.ServiceCall call, $0.TransactionIdGossipReq request);
}
