import 'package:blockchain/codecs.dart';
import 'package:blockchain/crypto/ed25519.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class TransactionAuthorizationValidation {
  Future<List<String>> validate(Transaction transaction);
}

class TransactionAuthorizationValidationImpl
    extends TransactionAuthorizationValidation {
  @override
  Future<List<String>> validate(Transaction transaction) async {
    for (final input in transaction.inputs) {
      final errors = await lockVerification(transaction, input.lock, input.key);
      if (errors.isNotEmpty) return errors;
    }
    return [];
  }

  static Future<List<String>> lockVerification(
      Transaction transaction, Lock lock, Key key) async {
    if (lock.hasEd25519() && key.hasEd25519()) {
      final isValid = await ed25519.verify(
          key.ed25519.signature, transaction.immutableBytes, lock.ed25519.vk);
      if (isValid)
        return [];
      else
        return ["Signature mismatch"];
    }
    return ["Invalid Lock/Key type"];
  }
}
