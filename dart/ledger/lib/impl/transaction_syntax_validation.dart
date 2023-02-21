import 'package:blockchain_protobuf/models/core.pb.dart';

List<String> validateTransactionSyntax(Transaction transaction) {
  final spentOutputReferences =
      transaction.inputs.map((i) => i.reference).toList();

  if (spentOutputReferences.length != spentOutputReferences.toSet().length) {
    return ["Transaction attempts to double-spend"];
  }
  return [];
}
