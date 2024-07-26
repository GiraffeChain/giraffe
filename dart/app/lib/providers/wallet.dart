import 'package:blockchain_app/providers/blockchain_reader_writer.dart';
import 'package:blockchain_app/providers/wallet_key.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallet.g.dart';

@riverpod
class PodWallet extends _$PodWallet {
  @override
  Stream<Wallet> build() {
    final view = ref.watch(podBlockchainReaderWriterProvider).view;
    final keyOpt = ref.watch(podWalletKeyProvider);
    if (keyOpt == null) {
      return const Stream.empty();
    } else {
      return Wallet.withDefaultKeyPair(keyOpt).streamed(view);
    }
  }
}
