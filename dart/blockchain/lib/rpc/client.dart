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
