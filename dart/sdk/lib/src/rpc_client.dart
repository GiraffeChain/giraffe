import 'package:blockchain_protobuf/services/node_rpc.pbgrpc.dart';
import 'package:blockchain_protobuf/services/staker_support_rpc.pbgrpc.dart';
import 'package:grpc/grpc.dart';
import 'package:ribs_effect/ribs_effect.dart';

class RpcClient {
  static Resource<ClientChannel> makeChannelResource(
          {String host = "localhost", int port = 2024, bool secure = false}) =>
      Resource.make(
          IO.delay(() => makeChannel(host: host, port: port, secure: secure)),
          (channel) => IO.fromFutureF(channel.shutdown).voided());
  static ClientChannel makeChannel(
          {String host = "localhost", int port = 2024, bool secure = false}) =>
      ClientChannel(
        host,
        port: port,
        options: ChannelOptions(
          credentials: secure
              ? ChannelCredentials.secure()
              : ChannelCredentials.insecure(),
          connectionTimeout: Duration(days: 365),
        ),
      );
}
