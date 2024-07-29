import 'package:grpc/grpc.dart';
import 'package:grpc/grpc_connection_interface.dart';

ClientChannelBase makeChannel(String host, int port, bool secure) {
  return ClientChannel(host,
      port: port,
      options: ChannelOptions(
          credentials: secure
              ? const ChannelCredentials.secure()
              : const ChannelCredentials.insecure()));
}
