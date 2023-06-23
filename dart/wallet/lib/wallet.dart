import 'dart:typed_data';

import 'package:blockchain_codecs/codecs.dart';
import 'package:blockchain_crypto/ed25519.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fpdart/fpdart.dart';

typedef Signer = Future<Transaction> Function(Transaction);

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

  bool applyTransaction(Transaction transaction) {
    var modified = false;
    for (final input in transaction.inputs) {
      if (spendableOutputs.remove(input.reference) != null) modified = true;
    }
    final txId = transaction.id;
    transaction.outputs.mapWithIndex((t, index) {
      final lock = locks[t.lockAddress];
      if (lock != null) {
        spendableOutputs[TransactionOutputReference()
          ..transactionId = txId
          ..index = index] = t;
        modified = true;
      }
    });
    return modified;
  }

  static Future<Wallet> initFromGenesis(Stream<FullBlock> blocks) async {
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
    final wallet = Wallet.empty();
    wallet.locks[lockAddress] = lock;
    wallet.signers[lockAddress] = signer;
    await blocks
        .asyncExpand(
            (block) => Stream.fromIterable(block.fullBody.transactions))
        .forEach(wallet.applyTransaction);
    return wallet;
  }
}
