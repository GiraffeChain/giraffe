import 'package:blockchain_protobuf/models/core.pb.dart';

class ConsensusValidator {
  final Future<Block> Function(BlockId) _fetchBlock;

  ConsensusValidator(this._fetchBlock);

  Future<List<String>> validate(Block block) async {
    final parent = await _fetchBlock(block.parentHeaderId);
    List<String> errors = [];
    if (block.height != parent.height + 1) errors.add("Invalid block height");
    if (block.timestamp <= parent.timestamp) errors.add("Invalid timestamp");

    return errors;
  }
}
