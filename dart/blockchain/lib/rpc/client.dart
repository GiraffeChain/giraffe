import 'package:blockchain/common/resource.dart';
import 'package:grpc/grpc.dart';

class RpcClient {
  static Resource<ClientChannel> makeChannel(
          {String host = "localhost", int port = 2024, bool secure = false}) =>
      Resource.make(
          () => Future.sync(() => ClientChannel(
                host,
                port: 2024,
                options: ChannelOptions(
                  credentials: secure
                      ? ChannelCredentials.secure()
                      : ChannelCredentials.insecure(),
                  connectionTimeout: Duration(days: 365),
                ),
              )),
          (channel) => channel.shutdown());
}
