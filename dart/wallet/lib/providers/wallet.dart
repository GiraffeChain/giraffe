import 'wallet_key.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallet.g.dart';

@riverpod
class PodWallet extends _$PodWallet {
  @override
  Future<Wallet> build() async {
    final keyOpt = ref.watch(podWalletKeyProvider);
    final Wallet wallet;
    if (keyOpt != null) {
      wallet = Wallet.withDefaultKeyPair(keyOpt);
    } else {
      wallet = await Wallet.genesis;
    }
    return wallet;
  }
}
