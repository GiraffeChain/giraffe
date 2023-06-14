import 'dart:async';

import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class ChainSelectionAlgebra {
  /**
   * Selects the "better" of the two block IDs
   */
  FutureOr<BlockId> select(BlockId a, BlockId b);
}
