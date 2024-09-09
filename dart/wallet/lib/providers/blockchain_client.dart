import 'settings.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'blockchain_client.g.dart';

@riverpod
class PodBlockchainClient extends _$PodBlockchainClient {
  @override
  BlockchainClient? build() {
    final settings = ref.watch(podSettingsProvider);
    switch (settings) {
      case AsyncData(:final value):
        final address = value.apiAddress;
        if (address == null) {
          return null;
        } else {
          return BlockchainClientFromJsonRpc(
            baseAddress: address,
          );
        }
      case AsyncLoading():
        return null;
      case AsyncError(:final error):
        return null;
      default:
        return null;
    }
  }
}
