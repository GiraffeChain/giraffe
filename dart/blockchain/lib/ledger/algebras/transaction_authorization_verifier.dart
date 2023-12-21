import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class TransactionAuthorizationVerifier {
  Future<List<String>> validate(Transaction transaction);
}
