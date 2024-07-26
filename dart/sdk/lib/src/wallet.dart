import 'dart:typed_data';

import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:collection/collection.dart';

typedef Signer = Future<Witness> Function(WitnessContext);

const _mapEq = MapEquality();

class Wallet {
  final Map<TransactionOutputReference, TransactionOutput> spendableOutputs;
  final Map<LockAddress, Lock> locks;
  final Map<LockAddress, Signer> signers;
  LockAddress defaultLockAddress;

  Wallet({
    required this.spendableOutputs,
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

  Stream<Wallet> streamed(BlockchainView client) async* {
    Future<bool> update() async {
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
      BlockchainView view, Transaction transaction) async {
    final messageToSign = transaction.signableBytes;
    final height = (await view.canonicalHead).height;
    for (final input in transaction.inputs) {
      final output = spendableOutputs[input.reference];
      if (output != null &&
          transaction.attestation
              .where((w) => w.lockAddress == output.lockAddress)
              .isEmpty) {
        final signer = signers[output.lockAddress]!;
        final context =
            WitnessContext(height: height, messageToSign: messageToSign);
        final witness = await signer(context);
        transaction.attestation.add(witness);
      }
    }

    return transaction;
  }
}
