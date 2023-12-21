import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class TransactionSyntaxVerifier {
  Future<List<String>> validate(Transaction transaction);
}
