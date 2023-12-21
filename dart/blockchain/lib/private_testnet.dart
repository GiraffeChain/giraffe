import 'dart:typed_data';

import 'package:blockchain/codecs.dart';
import 'package:blockchain/crypto/ed25519.dart';
import 'package:blockchain/crypto/kes.dart';
import 'package:blockchain/genesis.dart';
import 'package:blockchain/staker_initializer.dart';
import 'package:blockchain/crypto/utils.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';

class PrivateTestnet {
  static final DefaultTotalStake = BigInt.from(10000000);

  static Future<List<StakerInitializer>> stakerInitializers(
      Int64 timestamp, int stakerCount, TreeHeight kesTreeHeight) async {
    assert(stakerCount >= 0);
    final out = <StakerInitializer>[];
    for (int i = 0; i < stakerCount; i++) {
      final seed = await (timestamp.immutableBytes + i.immutableBytes).hash256;
      out.add(await StakerInitializer.fromSeed(seed, kesTreeHeight));
    }
    return out;
  }

  static Future<GenesisConfig> config(Int64 timestamp,
      List<StakerInitializer> stakers, List<Int64> stakes) async {
    assert(stakers.length == stakes.length);
    final transactions = [
      Transaction()
        ..outputs.add(TransactionOutput()
          ..lockAddress = (Lock()
                ..ed25519 = (Lock_Ed25519()
                  ..vk = (await ed25519.generateKeyPairFromSeed(Uint8List(32)))
                      .vk))
              .address
          ..value = (Value()..quantity = Int64(10000000))),
    ];
    for (int i = 0; i < stakers.length; i++) {
      final staker = stakers[i];
      final stake = stakes[i];
      transactions.addAll(await staker.genesisTransactions(stake));
    }

    return GenesisConfig(
        timestamp, transactions, GenesisConfig.DefaultEtaPrefix);
  }
}
