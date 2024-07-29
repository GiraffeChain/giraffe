import 'package:grpc/grpc_connection_interface.dart';
import 'package:ribs_effect/ribs_effect.dart';
import 'grpc/channel_factory.dart' as grpcFactory;

class RpcClient {
  static Resource<ClientChannelBase> makeChannelResource(
          {String host = "localhost", int port = 2024, bool secure = false}) =>
      Resource.make(
          IO.delay(() => makeChannel(host: host, port: port, secure: secure)),
          (channel) => IO.fromFutureF(channel.shutdown).voided());
  static ClientChannelBase makeChannel(
          {String host = "localhost", int port = 2024, bool secure = false}) =>
      grpcFactory.makeChannel(host, port, secure);
}
