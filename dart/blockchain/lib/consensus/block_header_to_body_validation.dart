import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class BlockHeaderToBodyValidation {
  Future<List<String>> validate(Block block);
}

class BlockHeaderToBodyValidationImpl extends BlockHeaderToBodyValidation {
  @override
  Future<List<String>> validate(Block block) async {
    return []; // TODO
  }
}
