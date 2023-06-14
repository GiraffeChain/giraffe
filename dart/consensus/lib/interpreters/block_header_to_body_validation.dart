import 'package:blockchain_consensus/algebras/block_header_to_body_validation_algebra.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

class BlockHeaderToBodyValidation extends BlockHeaderToBodyValidationAlgebra {
  @override
  Future<List<String>> validate(Block block) async {
    return []; // TODO
  }
}
