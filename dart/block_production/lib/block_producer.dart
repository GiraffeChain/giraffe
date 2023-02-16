import 'dart:async';

import 'package:blockchain_protobuf/models/block.pb.dart';

abstract class BlockProducer {
  Future<Block> produceBlock(Block parent);
}
