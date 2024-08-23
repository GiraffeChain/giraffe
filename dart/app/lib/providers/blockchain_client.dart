import 'package:blockchain_app/providers/json_rpc_client.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'blockchain_client.g.dart';

@riverpod
class PodBlockchainClient extends _$PodBlockchainClient {
  @override
  BlockchainClient build() {
    final client = ref.watch(podJsonRpcClientProvider);
    return BlockchainClientFromJsonRpc(client: client);
  }
}
