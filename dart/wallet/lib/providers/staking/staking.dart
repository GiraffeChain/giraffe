import 'dart:convert';
import 'dart:math';

import '../blockchain_client.dart';
import '../storage.dart';
import '../wallet.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:fixnum/fixnum.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../blockchain/minting/models/staker_data.dart';
import '../../blockchain/staking_account.dart';

part 'staking.g.dart';

@Riverpod(keepAlive: true)
class PodStaking extends _$PodStaking {
  @override
  StakerData? build() => null;

  Future<void> initMinting() async {
    final flutterSecureStorage = ref.read(podSecureStorageProvider);
    final stakerData = StakerData(
      vrfSk: base64Decode(
          (await flutterSecureStorage.read(key: "blockchain-staker-vrf-sk"))!),
      operatorSk: base64Decode((await flutterSecureStorage.read(
          key: "blockchain-staker-operator-sk"))!),
      account: TransactionOutputReference.fromBuffer(base64Decode(
          (await flutterSecureStorage.read(
              key: "blockchain-staker-account"))!)),
    );
    state = stakerData;
  }

  Future<void> initFromStakerData(StakerData stakerData) async {
    final secureStorage = ref.read(podSecureStorageProvider);
    await secureStorage.write(
        key: "blockchain-staker-vrf-sk",
        value: base64.encode(stakerData.vrfSk));
    await secureStorage.write(
        key: "blockchain-staker-account",
        value: base64.encode(stakerData.account.writeToBuffer()));
    await secureStorage.write(
        key: "blockchain-staker-operator-sk",
        value: base64.encode(stakerData.operatorSk));
    state = stakerData;
  }

  Future<void> register() async {
    final wallet = await ref.read(podWalletProvider.future);
    final random = Random.secure();
    final seed = List.generate(32, (_) => random.nextInt(255));
    final client = ref.read(podBlockchainClientProvider)!;
    final stakerInitializer = await StakingAccount.generate(
      Int64.ZERO,
      wallet.defaultLockAddress,
      seed,
    );
    final inputs = wallet.spendableOutputs.entries
        .where((e) =>
            e.value.hasAccount() || e.value.value.hasAccountRegistration())
        .map((e) => TransactionInput(reference: e.key, value: e.value.value))
        .toList();
    final outputs = List.of(stakerInitializer.transaction.outputs);
    final transaction = await wallet.payAndAttest(
        client, Transaction(inputs: inputs, outputs: outputs));
    await client.broadcastTransaction(transaction);
    final account =
        TransactionOutputReference(transactionId: transaction.id, index: 0);
    final secureStorage = ref.read(podSecureStorageProvider);
    await secureStorage.write(
        key: "blockchain-staker-vrf-sk",
        value: base64.encode(stakerInitializer.vrfSk));
    await secureStorage.write(
        key: "blockchain-staker-account",
        value: base64.encode(account.writeToBuffer()));
    await secureStorage.write(
        key: "blockchain-staker-operator-sk",
        value: base64.encode(stakerInitializer.operatorSk));
    await initMinting();
  }

  void reset() async {
    final flutterSecureStorage = ref.read(podSecureStorageProvider);
    await flutterSecureStorage.delete(key: "blockchain-staker-vrf-sk");
    await flutterSecureStorage.delete(key: "blockchain-staker-operator-sk");
    await flutterSecureStorage.delete(key: "blockchain-staker-account");
    state = null;
  }

  static final log = Logger("Blockchain.Staking");
}
