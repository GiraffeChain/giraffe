import 'dart:io';

import 'crypto/ed25519vrf.dart';
import 'crypto/kes.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:fixnum/fixnum.dart';
import 'package:hashlib/hashlib.dart';

class StakingAccount {
  final List<int> operatorSk;
  final List<int> operatorVk;
  final List<int> vrfSk;
  final List<int> vrfVk;
  final SecretKeyKesProduct kesSk;
  final SignatureKesProduct registrationSignature;
  final LockAddress lockAddress;
  final Int64 quantity;

  StakingAccount(
      {required this.operatorSk,
      required this.operatorVk,
      required this.vrfSk,
      required this.vrfVk,
      required this.kesSk,
      required this.registrationSignature,
      required this.lockAddress,
      required this.quantity});

  StakingAddress get stakingAddress => StakingAddress(value: operatorVk.base58);
  StakingRegistration get stakingRegistration => StakingRegistration(
      signature: registrationSignature, stakingAddress: stakingAddress);

  Transaction get transaction => Transaction(outputs: [
        TransactionOutput(
            lockAddress: lockAddress,
            value: Value(
                quantity: quantity,
                accountRegistration: AccountRegistration(
                    associationLock: lockAddress,
                    stakingRegistration: stakingRegistration)))
      ]);

  TransactionOutputReference get account =>
      TransactionOutputReference(transactionId: transaction.id, index: 0);

  Future<void> save(Directory directory) async {
    await directory.create(recursive: true);
    await File("${directory.path}/vrf").writeAsBytes(vrfSk);
    await File("${directory.path}/operator").writeAsBytes(operatorSk);
    await File("${directory.path}/kes").writeAsBytes(kesSk.encode);
    await File("${directory.path}/account")
        .writeAsBytes(account.writeToBuffer());
  }

  static Future<StakingAccount> generate(TreeHeight kesTreeHeight,
      Int64 quantity, LockAddress lockAddress, List<int> seed) async {
    final operatorKeyPair =
        await ed25519.generateKeyPairFromSeed([...seed, 0].hash256);
    final operatorVk = operatorKeyPair.vk;
    final vrfKeyPair =
        await ed25519Vrf.generateKeyPairFromSeed([...seed, 1].hash256);
    final vrfVk = vrfKeyPair.vk;
    final kesKeyPair = await kesProduct.generateKeyPair(
        [...seed, 2].hash256, kesTreeHeight, Int64.ZERO);
    final registrationMessageToSign =
        blake2b256.convert(vrfVk + operatorVk).bytes;
    final registrationSignature =
        await kesProduct.sign(kesKeyPair.sk, registrationMessageToSign);
    return StakingAccount(
      operatorSk: operatorKeyPair.sk,
      operatorVk: operatorVk,
      vrfSk: vrfKeyPair.sk,
      vrfVk: vrfVk,
      kesSk: kesKeyPair.sk,
      registrationSignature: registrationSignature,
      lockAddress: lockAddress,
      quantity: quantity,
    );
  }
}
