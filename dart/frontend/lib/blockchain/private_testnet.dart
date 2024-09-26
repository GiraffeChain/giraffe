import 'dart:typed_data';

import 'genesis.dart';
import 'staking_account.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:fixnum/fixnum.dart';

class PrivateTestnet {
  static final defaultTotalStake = BigInt.from(10000000);

  static Ed25519KeyPair? _ed25519keyPairCached;

  static Future<Ed25519KeyPair> get defaultKeyPair async {
    _ed25519keyPairCached ??=
        await ed25519.generateKeyPairFromSeed(Uint8List(32));

    return _ed25519keyPairCached!;
  }

  static Future<LockAddress> get defaultLockAddress => defaultKeyPair
      .then((kp) => Lock(ed25519: Lock_Ed25519(vk: kp.vk.base58)).address);

  static Future<List<StakingAccount>> stakerInitializers(
      Int64 timestamp, int stakerCount) async {
    assert(stakerCount >= 0);
    final out = <StakingAccount>[];
    for (int i = 0; i < stakerCount; i++) {
      final seed = (timestamp.immutableBytes + i.immutableBytes).hash256;
      out.add(await StakingAccount.generate(
          Int64(10000000), await defaultLockAddress, seed));
    }
    return out;
  }

  static Future<GenesisConfig> config(
      Int64 timestamp, List<StakingAccount> stakers, List<Int64> stakes) async {
    assert(stakers.length == stakes.length);
    final transactions = [
      Transaction()
        ..outputs.add(TransactionOutput()
          ..lockAddress = (Lock()
                ..ed25519 = (Lock_Ed25519()
                  ..vk = (await ed25519.generateKeyPairFromSeed(Uint8List(32)))
                      .vk
                      .base58))
              .address
          ..quantity = Int64(10000000)),
    ];
    for (int i = 0; i < stakers.length; i++) {
      final staker = stakers[i];
      transactions.add(staker.transaction);
    }

    return GenesisConfig(timestamp, transactions,
        GenesisConfig.defaultEtaPrefix, ProtocolSettings.defaultAsMap);
  }
}
