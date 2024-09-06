import 'package:giraffe_sdk/sdk.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:bip39/bip39.dart' as bip39;

part 'wallet_key.g.dart';

@Riverpod(keepAlive: true)
class PodWalletKey extends _$PodWalletKey {
  @override
  Ed25519KeyPair? build() => null;

  void setKey(Ed25519KeyPair? keyPair) {
    state = keyPair;
  }

  Future<void> import(String mnemonic, String passphrase) async {
    final seed = bip39.mnemonicToSeed(mnemonic, passphrase: passphrase);
    final keyPair = await ed25519.generateKeyPairFromSeed(seed);
    state = keyPair;
  }
}
