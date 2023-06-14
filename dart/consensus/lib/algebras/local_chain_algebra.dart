import 'dart:async';

import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class LocalChainAlgebra {
  FutureOr<void> adopt(BlockId newHead);
  FutureOr<BlockId> get currentHead;
  Stream<BlockId> get adoptions;
}
