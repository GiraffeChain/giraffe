//
//  Generated code. Do not modify.
//  source: services/staker_support_rpc.proto
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

import 'staker_support_rpc.pb.dart' as $0;

export 'staker_support_rpc.pb.dart';

@$pb.GrpcServiceName('blockchain.services.StakerSupportRpc')
class StakerSupportRpcClient extends $grpc.Client {
  static final _$broadcastBlock = $grpc.ClientMethod<$0.BroadcastBlockReq, $0.BroadcastBlockRes>(
      '/blockchain.services.StakerSupportRpc/BroadcastBlock',
      ($0.BroadcastBlockReq value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.BroadcastBlockRes.fromBuffer(value));
  static final _$getStaker = $grpc.ClientMethod<$0.GetStakerReq, $0.GetStakerRes>(
      '/blockchain.services.StakerSupportRpc/GetStaker',
      ($0.GetStakerReq value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.GetStakerRes.fromBuffer(value));
  static final _$getTotalActivestake = $grpc.ClientMethod<$0.GetTotalActiveStakeReq, $0.GetTotalActiveStakeRes>(
      '/blockchain.services.StakerSupportRpc/GetTotalActivestake',
      ($0.GetTotalActiveStakeReq value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.GetTotalActiveStakeRes.fromBuffer(value));
  static final _$calculateEta = $grpc.ClientMethod<$0.CalculateEtaReq, $0.CalculateEtaRes>(
      '/blockchain.services.StakerSupportRpc/CalculateEta',
      ($0.CalculateEtaReq value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.CalculateEtaRes.fromBuffer(value));
  static final _$packBlock = $grpc.ClientMethod<$0.PackBlockReq, $0.PackBlockRes>(
      '/blockchain.services.StakerSupportRpc/PackBlock',
      ($0.PackBlockReq value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.PackBlockRes.fromBuffer(value));

  StakerSupportRpcClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options,
        interceptors: interceptors);

  $grpc.ResponseFuture<$0.BroadcastBlockRes> broadcastBlock($0.BroadcastBlockReq request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$broadcastBlock, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetStakerRes> getStaker($0.GetStakerReq request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getStaker, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetTotalActiveStakeRes> getTotalActivestake($0.GetTotalActiveStakeReq request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getTotalActivestake, request, options: options);
  }

  $grpc.ResponseFuture<$0.CalculateEtaRes> calculateEta($0.CalculateEtaReq request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$calculateEta, request, options: options);
  }

  $grpc.ResponseStream<$0.PackBlockRes> packBlock($0.PackBlockReq request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$packBlock, $async.Stream.fromIterable([request]), options: options);
  }
}

@$pb.GrpcServiceName('blockchain.services.StakerSupportRpc')
abstract class StakerSupportRpcServiceBase extends $grpc.Service {
  $core.String get $name => 'blockchain.services.StakerSupportRpc';

  StakerSupportRpcServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.BroadcastBlockReq, $0.BroadcastBlockRes>(
        'BroadcastBlock',
        broadcastBlock_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.BroadcastBlockReq.fromBuffer(value),
        ($0.BroadcastBlockRes value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetStakerReq, $0.GetStakerRes>(
        'GetStaker',
        getStaker_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetStakerReq.fromBuffer(value),
        ($0.GetStakerRes value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetTotalActiveStakeReq, $0.GetTotalActiveStakeRes>(
        'GetTotalActivestake',
        getTotalActivestake_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetTotalActiveStakeReq.fromBuffer(value),
        ($0.GetTotalActiveStakeRes value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CalculateEtaReq, $0.CalculateEtaRes>(
        'CalculateEta',
        calculateEta_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CalculateEtaReq.fromBuffer(value),
        ($0.CalculateEtaRes value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PackBlockReq, $0.PackBlockRes>(
        'PackBlock',
        packBlock_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.PackBlockReq.fromBuffer(value),
        ($0.PackBlockRes value) => value.writeToBuffer()));
  }

  $async.Future<$0.BroadcastBlockRes> broadcastBlock_Pre($grpc.ServiceCall call, $async.Future<$0.BroadcastBlockReq> request) async {
    return broadcastBlock(call, await request);
  }

  $async.Future<$0.GetStakerRes> getStaker_Pre($grpc.ServiceCall call, $async.Future<$0.GetStakerReq> request) async {
    return getStaker(call, await request);
  }

  $async.Future<$0.GetTotalActiveStakeRes> getTotalActivestake_Pre($grpc.ServiceCall call, $async.Future<$0.GetTotalActiveStakeReq> request) async {
    return getTotalActivestake(call, await request);
  }

  $async.Future<$0.CalculateEtaRes> calculateEta_Pre($grpc.ServiceCall call, $async.Future<$0.CalculateEtaReq> request) async {
    return calculateEta(call, await request);
  }

  $async.Stream<$0.PackBlockRes> packBlock_Pre($grpc.ServiceCall call, $async.Future<$0.PackBlockReq> request) async* {
    yield* packBlock(call, await request);
  }

  $async.Future<$0.BroadcastBlockRes> broadcastBlock($grpc.ServiceCall call, $0.BroadcastBlockReq request);
  $async.Future<$0.GetStakerRes> getStaker($grpc.ServiceCall call, $0.GetStakerReq request);
  $async.Future<$0.GetTotalActiveStakeRes> getTotalActivestake($grpc.ServiceCall call, $0.GetTotalActiveStakeReq request);
  $async.Future<$0.CalculateEtaRes> calculateEta($grpc.ServiceCall call, $0.CalculateEtaReq request);
  $async.Stream<$0.PackBlockRes> packBlock($grpc.ServiceCall call, $0.PackBlockReq request);
}
