import 'dart:io';

import 'crypto/ed25519vrf.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:fixnum/fixnum.dart';
import 'package:hashlib/hashlib.dart';

class StakingAccount {
  final List<int> operatorSk;
  final List<int> operatorVk;
  final List<int> vrfSk;
  final List<int> vrfVk;
  final List<int> registrationSignature;
  final LockAddress lockAddress;
  final Int64 quantity;

  StakingAccount(
      {required this.operatorSk,
      required this.operatorVk,
      required this.vrfSk,
      required this.vrfVk,
      required this.registrationSignature,
      required this.lockAddress,
      required this.quantity});

  StakingRegistration get stakingRegistration => StakingRegistration(
      commitmentSignature: registrationSignature.base58, vk: operatorVk.base58);

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
    await File("${directory.path}/account")
        .writeAsBytes(account.writeToBuffer());
  }

  static Future<StakingAccount> generate(
      Int64 quantity, LockAddress lockAddress, List<int> seed) async {
    final operatorKeyPair =
        await ed25519.generateKeyPairFromSeed([...seed, 0].hash256);
    final operatorVk = operatorKeyPair.vk;
    final vrfKeyPair =
        await ed25519Vrf.generateKeyPairFromSeed([...seed, 1].hash256);
    final vrfVk = vrfKeyPair.vk;
    final registrationMessageToSign = blake2b256.convert(vrfVk).bytes;
    final registrationSignature =
        await ed25519.sign(registrationMessageToSign, operatorKeyPair.sk);
    return StakingAccount(
      operatorSk: operatorKeyPair.sk,
      operatorVk: operatorVk,
      vrfSk: vrfKeyPair.sk,
      vrfVk: vrfVk,
      registrationSignature: registrationSignature,
      lockAddress: lockAddress,
      quantity: quantity,
    );
  }
}
