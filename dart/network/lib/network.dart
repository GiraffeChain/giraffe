import 'package:blockchain_network/rpc_server.dart';
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
}
