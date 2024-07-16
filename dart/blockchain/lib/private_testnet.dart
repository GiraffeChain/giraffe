import 'dart:io';
import 'dart:typed_data';

import 'package:blockchain/codecs.dart';
import 'package:blockchain/consensus/models/protocol_settings.dart';
import 'package:blockchain/crypto/ed25519.dart';
import 'package:blockchain/crypto/kes.dart';
import 'package:blockchain/genesis.dart';
import 'package:blockchain/staker_initializer.dart';
import 'package:blockchain/crypto/utils.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';

class PrivateTestnet {
  static final DefaultTotalStake = BigInt.from(10000000);

  static Future<Ed25519KeyPair> get DefaultKeyPair =>
      ed25519.generateKeyPairFromSeed(Uint8List(32));
  static Future<LockAddress> get DefaultLockAddress => DefaultKeyPair.then(
      (kp) => Lock(ed25519: Lock_Ed25519(vk: kp.vk.base58)).address);

  static Future<BlockId> initTo(Directory baseDir, Int64 timestamp,
      List<Int64> stakes, TreeHeight kesTreeHeight) async {
    assert(stakes.isNotEmpty);
    final initializers =
        await stakerInitializers(timestamp, stakes.length, kesTreeHeight);
    final c = await config(timestamp, initializers, stakes);

    final genesis = c.block;

    final genesisId = genesis.header.id;

    final directory = Directory("${baseDir.path}/${genesisId.show}");
    if (await directory.exists()) return genesisId;

    await directory.create(recursive: true);

    await Genesis.save(Directory("${directory.path}/genesis"), genesis);

    for (int i = 0; i < initializers.length; i++) {
      final stakerDir = Directory("${directory.path}/stakers/$i");
      await initializers[i].save(stakerDir);
    }
    return genesisId;
  }

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
    final lockAddress = await DefaultLockAddress;
    final transactions = [
      Transaction()
        ..outputs.add(TransactionOutput()
          ..lockAddress = (Lock()
                ..ed25519 = (Lock_Ed25519()
                  ..vk = (await ed25519.generateKeyPairFromSeed(Uint8List(32)))
                      .vk
                      .base58))
              .address
          ..value = (Value()..quantity = Int64(10000000))),
    ];
    for (int i = 0; i < stakers.length; i++) {
      final staker = stakers[i];
      final stake = stakes[i];
      transactions.addAll(await staker.genesisTransactions(stake, lockAddress));
    }

    return GenesisConfig(timestamp, transactions,
        GenesisConfig.DefaultEtaPrefix, ProtocolSettings.defaultAsMap);
  }
}
