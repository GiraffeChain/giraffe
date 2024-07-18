import 'package:blockchain_protobuf/services/node_rpc.pbgrpc.dart';
import 'package:blockchain_protobuf/services/staker_support_rpc.pbgrpc.dart';
import 'package:grpc/grpc.dart';
import 'package:ribs_effect/ribs_effect.dart';

class RpcClient {
  static Resource<ClientChannel> makeChannel(
          {String host = "localhost", int port = 2024, bool secure = false}) =>
      Resource.make(
          IO.delay(() => ClientChannel(
                host,
                port: port,
                options: ChannelOptions(
                  credentials: secure
                      ? ChannelCredentials.secure()
                      : ChannelCredentials.insecure(),
                  connectionTimeout: Duration(days: 365),
                ),
              )),
          (channel) => IO.fromFutureF(channel.shutdown).voided());
}

class NodeRpcClientWithRetry extends NodeRpcClient {
  NodeRpcClientWithRetry(super.channel,
      {required this.delegate, required this.maxTries});

  final NodeRpcClient delegate;
  final int maxTries;

  ResponseFuture<BroadcastTransactionRes> broadcastTransaction(
          BroadcastTransactionReq request,
          {CallOptions? options}) =>
      _retry(maxTries, request,
          (v, o) => delegate.broadcastTransaction(v, options: o), options);

  ResponseFuture<GetBlockHeaderRes> getBlockHeader(GetBlockHeaderReq request,
          {CallOptions? options}) =>
      _retry(maxTries, request,
          (v, o) => delegate.getBlockHeader(v, options: o), options);

  ResponseFuture<GetBlockBodyRes> getBlockBody(GetBlockBodyReq request,
          {CallOptions? options}) =>
      _retry(maxTries, request, (v, o) => delegate.getBlockBody(v, options: o),
          options);

  ResponseFuture<GetFullBlockRes> getFullBlock(GetFullBlockReq request,
          {CallOptions? options}) =>
      _retry(maxTries, request, (v, o) => delegate.getFullBlock(v, options: o),
          options);

  ResponseFuture<GetTransactionRes> getTransaction(GetTransactionReq request,
          {CallOptions? options}) =>
      _retry(maxTries, request,
          (v, o) => delegate.getTransaction(v, options: o), options);

  ResponseFuture<GetBlockIdAtHeightRes> getBlockIdAtHeight(
          GetBlockIdAtHeightReq request,
          {CallOptions? options}) =>
      _retry(maxTries, request,
          (v, o) => delegate.getBlockIdAtHeight(v, options: o), options);

  ResponseStream<FollowRes> follow(FollowReq request, {CallOptions? options}) {
    // TODO: How to return a stream that retries if the return type _must_ be a ResponseStream?
    return delegate.follow(request, options: options);
  }
}

class StakerSupportRpcClientWithRetry extends StakerSupportRpcClient {
  StakerSupportRpcClientWithRetry(super.channel,
      {required this.delegate, required this.maxTries});

  final StakerSupportRpcClient delegate;
  final int maxTries;

  ResponseFuture<BroadcastBlockRes> broadcastBlock(BroadcastBlockReq request,
          {CallOptions? options}) =>
      _retry(maxTries, request,
          (v, o) => delegate.broadcastBlock(v, options: o), options);

  ResponseFuture<GetStakerRes> getStaker(GetStakerReq request,
          {CallOptions? options}) =>
      _retry(maxTries, request, (v, o) => delegate.getStaker(v, options: o),
          options);

  ResponseFuture<GetTotalActiveStakeRes> getTotalActivestake(
          GetTotalActiveStakeReq request,
          {CallOptions? options}) =>
      _retry(maxTries, request,
          (v, o) => delegate.getTotalActivestake(v, options: o), options);

  ResponseFuture<CalculateEtaRes> calculateEta(CalculateEtaReq request,
          {CallOptions? options}) =>
      _retry(maxTries, request, (v, o) => delegate.calculateEta(v, options: o),
          options);

  ResponseStream<PackBlockRes> packBlock(PackBlockReq request,
          {CallOptions? options}) =>
      // TODO: How to return a stream that retries if the return type _must_ be a ResponseStream?
      delegate.packBlock(request, options: options);
}

ResponseFuture<O> _retry<I, O>(int maxTries, I request,
    ResponseFuture<O> Function(I, CallOptions?) f, CallOptions? options) {
  int i = maxTries;
  late Object error;
  while (i >= 0) {
    try {
      return f(request, options);
    } catch (e) {
      i--;
      error = e;
    }
  }
  throw error;
}
