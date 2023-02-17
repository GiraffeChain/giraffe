import 'package:blockchain_network/rpc_server.dart';
import 'package:blockchain_protobuf/services/node_rpc.pbgrpc.dart';
import 'package:grpc/grpc.dart';

class Network {
  final Server _server;

  Network(this._server);

  static Future<Network> make(
      String host, int port, RpcServer implementation) async {
    final server = Server([implementation]);
    await server.serve(address: host, port: port);
    return Network(server);
  }

  Future<void> close() {
    return _server.shutdown();
  }

  Future<NodeRpcClient> connectTo(String address) async {
    final split = address.split(":");
    final host = split[0];
    final port = int.parse(split[1]);
    final channel = ClientChannel(host,
        port: port,
        options: ChannelOptions(credentials: ChannelCredentials.insecure()));
    return NodeRpcClient(channel);
  }
}
