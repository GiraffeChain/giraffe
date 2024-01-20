import 'dart:io';

import 'package:blockchain/crypto/ed25519.dart';
import 'package:blockchain/crypto/ed25519vrf.dart';
import 'package:blockchain/crypto/kes.dart';
import 'package:blockchain/crypto/utils.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';

class StakerInitializer {
  final Ed25519KeyPair operatorKeyPair;
  final Ed25519VRFKeyPair vrfKeyPair;
  final KeyPairKesProduct kesKeyPair;

  StakerInitializer(this.operatorKeyPair, this.vrfKeyPair, this.kesKeyPair);

  static Future<StakerInitializer> fromSeed(
      List<int> seed, TreeHeight treeHeight) async {
    final operatorKeyPair =
        await ed25519.generateKeyPairFromSeed(await (seed + [1]).hash256);
    final vrfKeyPair =
        await ed25519Vrf.generateKeyPairFromSeed(await (seed + [3]).hash256);
    final kesKeyPair = await kesProduct.generateKeyPair(
        await (seed + [4]).hash256, treeHeight, Int64.ZERO);

    return StakerInitializer(
      operatorKeyPair,
      vrfKeyPair,
      kesKeyPair,
    );
  }

  Future<SignatureKesProduct> get registrationSignature async =>
      kesProduct.sign(
        kesKeyPair.sk,
        await (vrfKeyPair.vk + operatorKeyPair.vk).hash256,
      );

  Future<StakingRegistration> get registration async => StakingRegistration()
    ..signature = await registrationSignature
    ..stakingAddress = stakingAddress;

  StakingAddress get stakingAddress =>
      StakingAddress()..value = operatorKeyPair.vk;

  Future<List<Transaction>> genesisTransactions(
      Int64 stake, LockAddress lockAddress) async {
    throw UnimplementedError();
    return [
      Transaction()
        ..outputs.add(TransactionOutput()
          ..lockAddress = lockAddress
          ..value = (Value()..quantity = stake))
    ];
  }

  Future<void> save(Directory directory) async {
    await Directory("${directory.path}/kes").create(recursive: true);
    await File("${directory.path}/vrf").writeAsBytes(vrfKeyPair.sk);
    await File("${directory.path}/operator").writeAsBytes(operatorKeyPair.sk);
    await File("${directory.path}/kes/0").writeAsBytes(kesKeyPair.sk.encode);
  }
}
