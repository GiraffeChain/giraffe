
import 'dart:async';

import 'package:blockchain_protobuf/models/block.pb.dart';

abstract class BlockProducer {
  FutureOr<Block> produceBlock(Block parent);
}
