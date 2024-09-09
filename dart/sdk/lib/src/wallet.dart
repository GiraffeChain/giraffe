import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:collection/collection.dart';

typedef Signer = Future<Witness> Function(WitnessContext);

const _mapEq = MapEquality();

class Wallet {
  final Map<TransactionOutputReference, TransactionOutput> spendableOutputs;
  final Map<TransactionOutputReference, TransactionOutput> pendingOutputs;
  final Map<LockAddress, Lock> locks;
  final Map<LockAddress, Signer> signers;
  LockAddress defaultLockAddress;

  Wallet({
    required this.spendableOutputs,
    required this.pendingOutputs,
    required this.locks,
    required this.signers,
    required this.defaultLockAddress,
  });

  factory Wallet.withDefaultKeyPair(Ed25519KeyPair keyPair) {
    final lock = Lock()..ed25519 = (Lock_Ed25519()..vk = keyPair.vk.base58);
    final lockAddress = lock.address;
    final Signer signer = (context) async {
      return Witness(
        lock: lock,
        lockAddress: lockAddress,
        key: (Key()
          ..ed25519 = (Key_Ed25519()
            ..signature =
                (await ed25519.sign(context.messageToSign, keyPair.sk))
                    .base58)),
      );
    };
    return Wallet(
      spendableOutputs: {},
      pendingOutputs: {},
      locks: {lockAddress: lock},
      signers: {lockAddress: signer},
      defaultLockAddress: lockAddress,
    );
  }

  static Future<Wallet> get genesis async => Wallet.withDefaultKeyPair(
      await ed25519.generateKeyPairFromSeed(Uint8List(32)));

  @override
  int get hashCode => Object.hash(spendableOutputs, locks, signers);

  @override
  bool operator ==(Object other) {
    if (other is Wallet) {
      return _mapEq.equals(spendableOutputs, other.spendableOutputs) &&
          _mapEq.equals(locks, other.locks) &&
          _mapEq.equals(signers, other.signers);
    }
    return false;
  }

  Future<void> addPrivateGenesisKey() async =>
      addKeyPair(await ed25519.generateKeyPairFromSeed(Uint8List(32)));

  void addLockAddress(LockAddress lockAddress, Lock lock, Signer signer,
      {bool isDefault = true}) {
    locks[lockAddress] = lock;
    signers[lockAddress] = signer;
    if (isDefault) defaultLockAddress = lockAddress;
  }

  void addKeyPair(Ed25519KeyPair keyPair, {bool isDefault = true}) {
    final lock = Lock()..ed25519 = (Lock_Ed25519()..vk = keyPair.vk.base58);
    final lockAddress = lock.address;
    final Signer signer = (context) async {
      return Witness(
        lock: lock,
        lockAddress: lockAddress,
        key: (Key()
          ..ed25519 = (Key_Ed25519()
            ..signature =
                (await ed25519.sign(context.messageToSign, keyPair.sk))
                    .base58)),
      );
    };
    addLockAddress(lockAddress, lock, signer, isDefault: isDefault);
  }

  Stream<Wallet> streamed(BlockchainClient client) async* {
    Future<bool> update() async {
      pendingOutputs.clear();
      var wasUpdated = false;
      for (final address in locks.keys) {
        final utxos = await client.getLockAddressState(address);
        final toRemove = <TransactionOutputReference>{};
        for (final utxo in spendableOutputs.keys) {
          if (!utxos.contains(utxo)) {
            wasUpdated = true;
            toRemove.add(utxo);
          }
        }
        for (final utxo in toRemove) {
          spendableOutputs.remove(utxo);
        }
        for (final utxo in utxos) {
          if (!spendableOutputs.containsKey(utxo)) {
            wasUpdated = true;
            final output = await client.getTransactionOutput(utxo);
            spendableOutputs[utxo] = output!;
          }
        }
      }
      return wasUpdated;
    }

    await update();
    yield this;
    await for (final _ in client.traversal) {
      if (await update()) yield this;
    }
  }

  Future<Transaction> attest(
      BlockchainClient view, Transaction transaction) async {
    final messageToSign = transaction.signableBytes;
    final height = (await view.canonicalHead).height;
    final context =
        WitnessContext(height: height, messageToSign: messageToSign);
    final requiredWitnesses =
        await transaction.requiredWitnesses(view.getTransactionOutputOrRaise);
    for (final address in requiredWitnesses) {
      if (transaction.attestation.indexWhere((w) => w.lockAddress == address) ==
          -1) {
        final signer = signers[address]!;
        final witness = await signer(context);
        transaction.attestation.add(witness);
      }
    }
    return transaction;
  }

  /// First, establishes that all outputs of the given transaction have the required minimum quantity. If not, they will be updated to the correct minimum.
  /// Next, if the current transaction tip/reward exceeds the default minimum, the change is sent back to the local wallet as a new output.
  /// Otherwise, payment tokens will be spent from the wallet to cover the remaining tip/reward.
  ///
  Future<Transaction> pay(
      BlockchainClient view, Transaction transaction) async {
    for (final output in transaction.outputs) {
      final minQuantity = output.requiredMinimumQuantity;
      if (output.value.quantity < minQuantity) {
        output.value.quantity = minQuantity;
      }
    }
    var currentReward = transaction.reward;
    final remainingSpendableOutputs = QueueList.from(Map.of(spendableOutputs)
        .entries
        .where((e) => e.value.isPaymentToken)
        .sortedByCompare(
            (e) => e.value.value.quantity, (a, b) => a.compareTo(b)));
    while (currentReward != defaultTransactionTip) {
      if (currentReward > defaultTransactionTip) {
        final output = TransactionOutput(
            lockAddress: defaultLockAddress,
            value: Value(quantity: currentReward - defaultTransactionTip));
        transaction.outputs.add(output);
        currentReward = defaultTransactionTip;
      } else if (remainingSpendableOutputs.isEmpty) {
        throw Exception('Insufficient funds');
      } else {
        final out = remainingSpendableOutputs.removeFirst();
        final input =
            TransactionInput(reference: out.key, value: out.value.value);
        transaction.inputs.add(input);
        currentReward += out.value.value.quantity;
      }
    }
    transaction.embedId();
    for (final input in transaction.inputs) {
      if (spendableOutputs.containsKey(input.reference)) {
        pendingOutputs[input.reference] = spendableOutputs[input.reference]!;
        spendableOutputs.remove(input.reference);
      }
    }
    for (int i = 0; i < transaction.outputs.length; i++) {
      final output = transaction.outputs[i];
      if (locks.containsKey(output.lockAddress)) {
        final reference =
            TransactionOutputReference(transactionId: transaction.id, index: i);
        spendableOutputs[reference] = output;
      }
    }
    return transaction;
  }

  Future<Transaction> payAndAttest(
          BlockchainClient view, Transaction transaction) async =>
      attest(view, await pay(view, transaction));

  Int64 get totalFunds => spendableOutputs.values
      .map((v) => v.value.quantity)
      .fold(Int64.ZERO, (a, b) => a + b);

  Int64 get stakedFunds => spendableOutputs.values
      .where((v) => v.hasAccount() || v.value.hasAccountRegistration())
      .map((v) => v.value.quantity)
      .fold(Int64.ZERO, (a, b) => a + b);

  Int64 get liquidFunds => spendableOutputs.values
      .where((o) => o.isPaymentToken)
      .map((v) => v.value.quantity)
      .fold(Int64.ZERO, (a, b) => a + b);
}
