import 'dart:typed_data';

import 'package:blockchain/blockchain_view.dart';
import 'package:blockchain/codecs.dart';
import 'package:blockchain/crypto/ed25519.dart';
import 'package:blockchain/ledger/models/transaction_validation_context.dart';
import 'package:blockchain/traversal.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:collection/collection.dart';
import 'package:fpdart/fpdart.dart';

typedef Signer = Future<Witness> Function(WitnessContext);

const _mapEq = MapEquality();

class Wallet {
  final Map<TransactionOutputReference, TransactionOutput> spendableOutputs;
  final Map<TransactionOutputReference, TransactionOutput> spentOutputs;
  final Map<LockAddress, Lock> locks;
  final Map<LockAddress, Signer> signers;

  Wallet(
      {required this.spendableOutputs,
      required this.spentOutputs,
      required this.locks,
      required this.signers});

  factory Wallet.empty() {
    return Wallet(
        spendableOutputs: {}, spentOutputs: {}, locks: {}, signers: {});
  }

  static Stream<Wallet> streamed(BlockchainView blockchain) async* {
    Wallet wallet = Wallet.empty();
    await wallet.addPrivateGenesisKey();
    await for (final block in blockchain.replayBlocks) {
      for (final transaction in block.fullBody.transactions) {
        wallet.applyTransaction(transaction);
      }
    }
    yield wallet;
    await for (final step in blockchain.traversal) {
      if (step is TraversalStep_Applied) {
        final block = await blockchain.getFullBlockOrRaise(step.blockId);
        for (final transaction in block.fullBody.transactions) {
          wallet.applyTransaction(transaction);
        }
      } else if (step is TraversalStep_Unapplied) {
        final block = await blockchain.getFullBlockOrRaise(step.blockId);
        for (final transaction in block.fullBody.transactions.reversed) {
          wallet.unapplyTransaction(transaction);
        }
      }
      yield wallet;
    }
  }

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

  void applyTransaction(Transaction transaction) {
    for (final input in transaction.inputs) {
      spendableOutputs.remove(input.reference);
    }
    final txId = transaction.id;
    transaction.outputs.mapWithIndex((t, index) {
      final lock = locks[t.lockAddress];
      if (lock != null) {
        spendableOutputs[TransactionOutputReference()
          ..transactionId = txId
          ..index = index] = t;
      }
    }).toList();
  }

  void unapplyTransaction(Transaction transaction) {
    final txId = transaction.id;
    for (int i = transaction.outputs.length - 1; i >= 0; i--) {
      final reference = TransactionOutputReference()
        ..transactionId = txId
        ..index = i;
      spendableOutputs.remove(reference);
    }

    for (final input in transaction.inputs.reversed) {
      if (spentOutputs.containsKey(input.reference)) {
        spendableOutputs[input.reference] = spentOutputs[input.reference]!;
        spentOutputs.remove(input.reference);
      }
    }
  }

  Future<void> addPrivateGenesisKey() async {
    final genesisKeyPair = await ed25519.generateKeyPairFromSeed(Uint8List(32));
    final lock = Lock()..ed25519 = (Lock_Ed25519()..vk = genesisKeyPair.vk);
    final lockAddress = lock.address;
    final Signer signer = (context) async {
      return Witness(
        lock: lock,
        lockAddress: lockAddress,
        key: (Key()
          ..ed25519 = (Key_Ed25519()
            ..signature =
                await ed25519.sign(context.messageToSign, genesisKeyPair.sk))),
      );
    };
    locks[lockAddress] = lock;
    signers[lockAddress] = signer;
  }

  static Future<Wallet> initFromGenesis(Stream<FullBlock> blocks) async {
    final wallet = Wallet.empty();
    await wallet.addPrivateGenesisKey();
    await blocks
        .asyncExpand(
            (block) => Stream.fromIterable(block.fullBody.transactions))
        .forEach(wallet.applyTransaction);
    return wallet;
  }
}
