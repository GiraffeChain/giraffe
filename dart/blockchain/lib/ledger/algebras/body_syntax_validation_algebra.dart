import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class BodySyntaxValidationAlgebra {
  Future<List<String>> validate(BlockBody body);
}
