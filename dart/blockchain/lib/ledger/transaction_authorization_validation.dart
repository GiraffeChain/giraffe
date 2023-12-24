import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class TransactionAuthorizationValidation {
  Future<List<String>> validate(Transaction transaction);
}

class TransactionAuthorizationValidationImpl
    extends TransactionAuthorizationValidation {
  @override
  Future<List<String>> validate(Transaction transaction) async {
    for (final input in transaction.inputs) {
      final errors = lockVerification(input.lock, input.key);
      if (errors.isNotEmpty) return errors;
    }
    return [];
  }

  static List<String> lockVerification(Lock lock, Key key) {
    // TODO
    if (lock.hasEd25519() && key.hasEd25519()) return [];
    return ["Invalid Lock/Key type"];
  }
}
