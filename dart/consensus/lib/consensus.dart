import 'dart:async';

import 'package:blockchain_protobuf/models/block.pb.dart';

abstract class Consensus {
  Future<BlockId> chainPreference(BlockId chainAHead, BlockId chainBHead);
  Future<List<String>> validate(Block block);
  Future<BlockId> get currentHead;
  Future<void> adopt(BlockId newHead);
  Stream<BlockId> get adoptions;
}
