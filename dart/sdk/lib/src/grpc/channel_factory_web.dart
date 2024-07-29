import 'package:grpc/grpc_connection_interface.dart';
import 'package:grpc/grpc_web.dart';

ClientChannelBase makeChannel(String host, int port, bool secure) {
  final prefix = secure ? "https://" : "http://";
  final uri = "$prefix$host:$port";
  return GrpcWebClientChannel.xhr(Uri.parse(uri));
}
