import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class BodyAuthorizationValidationAlgebra {
  Future<List<String>> validate(BlockBody body);
}
