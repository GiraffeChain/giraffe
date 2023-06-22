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
      {this.spendableOutputs = const {},
      this.locks = const {},
      this.signers = const {}});

  void applyTransaction(Transaction transaction) {
    transaction.inputs.forEach((i) => spendableOutputs.remove(i));
    final txId = transaction.id;
    transaction.outputs.mapWithIndex((t, index) {
      final lock = locks[t.lockAddress];
      if (lock != null) {
        spendableOutputs[TransactionOutputReference()
          ..transactionId = txId
          ..index = index];
      }
    });
  }

  static Future<Wallet> initFromGenesis(Stream<FullBlock> blocks) async {
    final genesisKeyPair = await ed25519.generateKeyPairFromSeed(Uint8List(32));
    final lock = Lock()..ed25519 = (Lock_Ed25519()..vk = genesisKeyPair.vk);
    final lockAddress = lock.address;
    final Signer signer = (tx) => Future.value(tx);
    final wallet = Wallet();
    wallet.locks[lockAddress] = lock;
    wallet.signers[lockAddress] = signer;
    await blocks
        .asyncExpand(
            (block) => Stream.fromIterable(block.fullBody.transactions))
        .forEach(wallet.applyTransaction);
    return wallet;
  }
}
