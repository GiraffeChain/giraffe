import 'package:blockchain/ledger/algebras/transaction_authorization_verifier.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

class TransactionAuthorizationInterpreter
    extends TransactionAuthorizationVerifier {
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
