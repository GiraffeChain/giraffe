import 'package:blockchain_network/authenticated_rpc.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_protobuf/services/node_rpc.pbgrpc.dart';
import 'package:grpc/grpc.dart';

class Network {
  final Server _server;
  final String localAddress;
  final BlockId genesisBlockId;
  final Set<String> inboundPeers;
  final Map<String, NodeRpcClient> outboundPeers;

  Network(this._server, this.localAddress, this.genesisBlockId,
      this.inboundPeers, this.outboundPeers);

  static Future<Network> make(
      String host,
      int port,
      BlockId genesisBlockId,
      NodeRpcServiceBase implementation,
      void Function(String) inboundPeer) async {
    final Set<String> inboundPeers = Set();
    final authenticatedImplementation = AuthenticatedGrpcServer(
      implementation,
      (peer) {
        inboundPeers.add(peer);
        inboundPeer(peer);
      },
    );
    final server = Server([authenticatedImplementation]);
    await server.serve(address: host, port: port);
    return Network(server, "${host}:${port}", genesisBlockId, inboundPeers, {});
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
    final client = AuthenticatedRpcClient(channel, localAddress);

    outboundPeers[address] = client;

    await client.handshake(HandshakeReq()
      ..genesisBlockId = genesisBlockId
      ..p2pAddress = localAddress);
    return client;
  }
}
