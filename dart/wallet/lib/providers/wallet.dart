import 'blockchain_client.dart';
import 'wallet_key.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallet.g.dart';

@riverpod
class PodWallet extends _$PodWallet {
  @override
  Stream<Wallet> build() {
    final keyOpt = ref.watch(podWalletKeyProvider);
    if (keyOpt == null) {
      return const Stream.empty();
    } else {
      final client = ref.watch(podBlockchainClientProvider);
      return Wallet.withDefaultKeyPair(keyOpt).streamed(client);
    }
  }
}