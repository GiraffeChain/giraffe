import 'dart:convert';

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

  void setWalletSk(List<int> sk) {
    state.write(key: _walletSkKey, value: base64Encode(sk));
  }

  Future<List<int>?> get getWalletSk async {
    final str = await state.read(key: _walletSkKey);
    if (str != null) {
      return base64Decode(str);
    } else {
      return null;
    }
  }

  Future<bool> get containsWalletSk => state.containsKey(key: _walletSkKey);

  Future<void> deleteWalletSk() => state.delete(key: _walletSkKey);
}

const _walletSkKey = 'wallet_sk';
