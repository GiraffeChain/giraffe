import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<bool> directoryContainsStakingFiles(String dir) async =>
    (await File("$dir/vrf").exists()) &&
    (await File("$dir/operator").exists()) &&
    (await File("$dir/account").exists()) &&
    (await File("$dir/kes").exists());

Future<void> initMintingFromDirectory(
    String path, FlutterSecureStorage secureStorage) async {
  final isStaking = await directoryContainsStakingFiles(path);
  assert(isStaking, "Directory does not contain staking files");
  secureStorage.write(
      key: "blockchain-staker-vrf-sk",
      value: base64.encode(await File("$path/vrf").readAsBytes()));
  secureStorage.write(
      key: "blockchain-staker-account",
      value: base64.encode(await File("$path/account").readAsBytes()));
  secureStorage.write(
      key: "blockchain-staker-kes",
      value: base64.encode(await File("$path/kes").readAsBytes()));
}
