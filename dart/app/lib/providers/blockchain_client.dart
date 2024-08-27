import 'package:blockchain_app/providers/settings.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'blockchain_client.g.dart';

@riverpod
class PodBlockchainClient extends _$PodBlockchainClient {
  @override
  BlockchainClient build() {
    final settings = ref.watch(podSettingsProvider);
    return BlockchainClientFromJsonRpc(
      baseAddress:
          "${settings.secure ? 'https' : 'http'}://${settings.host}:${settings.port}/api",
    );
  }
}
