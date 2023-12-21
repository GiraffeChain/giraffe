import 'package:blockchain/ledger/models/body_validation_context.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class BodySemanticValidationAlgebra {
  Future<List<String>> validate(BlockBody body, BodyValidationContext context);
}
