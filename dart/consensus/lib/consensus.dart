import 'dart:async';

import 'package:blockchain_protobuf/models/block.pb.dart';

abstract class Consensus {
  FutureOr<BlockId> selectChain(BlockId chainAHead, BlockId chainBHead);
  FutureOr<List<String>> validate(Block block);
}
