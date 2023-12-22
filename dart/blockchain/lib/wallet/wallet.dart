import 'dart:typed_data';

import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/event_sourced_state.dart';
import 'package:blockchain/common/parent_child_tree.dart';
import 'package:blockchain/crypto/ed25519.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:collection/collection.dart';
import 'package:fpdart/fpdart.dart';

typedef Signer = Future<Transaction> Function(Transaction);
typedef WalletESS = EventSourcedStateAlgebra<Wallet, BlockId>;

class WalletEventSourcedState {
  static WalletESS make(
    Wallet initialWallet,
    Future<BlockBody> Function(BlockId) fetchBlockBody,
    Future<Transaction> Function(TransactionId) fetchTransaction,
    ParentChildTree<BlockId> parentChildTree,
    // TODO: Persistent
    BlockId genesisParentId,
  ) {
    return EventTreeState<Wallet, BlockId>(
      (state, blockId) async {
        final body = await fetchBlockBody(blockId);
        for (final txId in body.transactionIds) {
          state.applyTransaction(await fetchTransaction(txId));
        }
        return state;
      },
      (state, blockId) async {
        final body = await fetchBlockBody(blockId);
        for (final txId in body.transactionIds.reversed) {
          state.unapplyTransaction(await fetchTransaction(txId));
        }
        return state;
      },
      parentChildTree,
      initialWallet,
      genesisParentId,
      (p0) async {},
    );
  }
}

const _mapEq = MapEquality();

class Wallet {
  final Map<TransactionOutputReference, TransactionOutput> spendableOutputs;
  final Map<LockAddress, Lock> locks;
  final Map<LockAddress, Signer> signers;

  Wallet(
      {required this.spendableOutputs,
      required this.locks,
      required this.signers});

  factory Wallet.empty() {
    return Wallet(spendableOutputs: {}, locks: {}, signers: {});
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
    });
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
      final lockAddress = input.lock.address;
      if (locks.containsKey(lockAddress)) {
        spendableOutputs[input.reference] = TransactionOutput()
          ..lockAddress = lockAddress
          ..value = input.value;
      }
    }
  }

  Future<void> addPrivateGenesisKey() async {
    final genesisKeyPair = await ed25519.generateKeyPairFromSeed(Uint8List(32));
    final lock = Lock()..ed25519 = (Lock_Ed25519()..vk = genesisKeyPair.vk);
    final lockAddress = lock.address;
    // TODO
    final Signer signer = (tx) async {
      for (final input in tx.inputs) {
        if (input.lock == lock)
          input.key =
              (Key()..ed25519 = (Key_Ed25519()..signature = Uint8List(64)));
      }
      return tx;
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
