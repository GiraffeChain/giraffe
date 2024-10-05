import 'dart:convert';
import 'dart:math';

import 'package:giraffe_protocol/protocol.dart';

import '../blockchain_client.dart';
import '../storage.dart';
import '../wallet.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:fixnum/fixnum.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'staking.g.dart';

@Riverpod(keepAlive: true)
class PodStaking extends _$PodStaking {
  @override
  Future<StakerData?> build() => Future.value(null);

  Future<void> initMinting() async {
    final flutterSecureStorage = ref.read(podSecureStorageProvider);
    state = AsyncValue.loading();
    try {
      final stakerData = StakerData(
        vrfSk: base64Decode((await flutterSecureStorage.read(
            key: "blockchain-staker-vrf-sk"))!),
        operatorSk: base64Decode((await flutterSecureStorage.read(
            key: "blockchain-staker-operator-sk"))!),
        account: TransactionOutputReference.fromBuffer(base64Decode(
            (await flutterSecureStorage.read(
                key: "blockchain-staker-account"))!)),
      );
      state = AsyncValue.data(stakerData);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> initFromStakerData(StakerData stakerData) async {
    final secureStorage = ref.read(podSecureStorageProvider);
    try {
      await secureStorage.write(
          key: "blockchain-staker-vrf-sk",
          value: base64.encode(stakerData.vrfSk));
      await secureStorage.write(
          key: "blockchain-staker-account",
          value: base64.encode(stakerData.account.writeToBuffer()));
      await secureStorage.write(
          key: "blockchain-staker-operator-sk",
          value: base64.encode(stakerData.operatorSk));
      state = AsyncValue.data(stakerData);
      state = AsyncValue.data(stakerData);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> unregister() async {
    final wallet = await ref.read(podWalletProvider.future);
    final client = ref.read(podBlockchainClientProvider)!;
    final tx1Inputs = wallet.spendableOutputs.entries
        .where((e) => e.value.hasAccount())
        .map((e) => TransactionInput(reference: e.key))
        .toList();
    if (tx1Inputs.isNotEmpty) {
      final tx = await wallet.payAndAttest(
          client, Transaction(inputs: tx1Inputs, outputs: []));
      await client.broadcastTransaction(tx);
      await client.confirmTransaction(tx.id);
    }
    final tx2Inputs = wallet.spendableOutputs.entries
        .where((e) => e.value.hasAccountRegistration())
        .map((e) => TransactionInput(reference: e.key))
        .toList();
    if (tx2Inputs.isNotEmpty) {
      final tx = await wallet.payAndAttest(
          client, Transaction(inputs: tx2Inputs, outputs: []));
      await client.broadcastTransaction(tx);
      await client.confirmTransaction(tx.id);
    }
  }

  Future<void> register() async {
    state = AsyncValue.loading();
    try {
      await unregister();
      final wallet = await ref.read(podWalletProvider.future);
      final random = Random.secure();
      final seed = List.generate(32, (_) => random.nextInt(255));
      final client = ref.read(podBlockchainClientProvider)!;
      final stakerInitializer = await StakingAccount.generate(
        Int64.ZERO,
        wallet.defaultLockAddress,
        seed,
      );
      final outputs = List.of(stakerInitializer.transaction.outputs);
      final transaction = await wallet.payAndAttest(
          client, Transaction(inputs: [], outputs: outputs));
      await client.broadcastTransaction(transaction);
      await client.confirmTransaction(transaction.id);
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
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  void reset() async {
    state = AsyncValue.data(null);
    final flutterSecureStorage = ref.read(podSecureStorageProvider);
    await flutterSecureStorage.delete(key: "blockchain-staker-vrf-sk");
    await flutterSecureStorage.delete(key: "blockchain-staker-operator-sk");
    await flutterSecureStorage.delete(key: "blockchain-staker-account");
    await unregister();
  }

  static final log = Logger("Blockchain.Staking");
}
