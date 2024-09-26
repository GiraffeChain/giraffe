import 'package:giraffe_sdk/sdk.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'blockchain_client.dart';
import 'wallet.dart';

part 'graph_client.g.dart';

@riverpod
class PodGraphClient extends _$PodGraphClient {
  @override
  Future<Graph> build() async {
    final client = ref.read(podBlockchainClientProvider)!;
    final wallet = await ref.watch(podWalletProvider.future);
    return Graph(wallet: wallet, client: client);
  }
}
