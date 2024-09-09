import 'dart:typed_data';

import 'package:fast_base58/fast_base58.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'storage.g.dart';

@riverpod
class PodSecureStorage extends _$PodSecureStorage {
  @override
  FlutterSecureStorage build() => const FlutterSecureStorage(
          aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ));

  Future<void> setWalletSk(List<int> sk) async {
    final str = Base58Encode(sk);
    await deleteWalletSk();
    await state.write(key: _walletSkKey, value: str);
  }

  Future<Uint8List?> get getWalletSk async {
    final str = await state.read(key: _walletSkKey);
    if (str != null) {
      return Uint8List.fromList(Base58Decode(str));
    } else {
      return null;
    }
  }

  Future<bool> get containsWalletSk => state.containsKey(key: _walletSkKey);

  Future<void> deleteWalletSk() => state.delete(key: _walletSkKey);

  Future<void> setApiAddress(String url) async {
    await state.write(key: _apiUrlKey, value: url);
  }

  Future<String?> get apiAddress => state.read(key: _apiUrlKey);
}

const _walletSkKey = 'wallet_sk';
const _apiUrlKey = 'api_address';
