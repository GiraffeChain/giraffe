import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class BlockHeaderToBodyValidationAlgebra {
  Future<List<String>> validate(Block block);
}
