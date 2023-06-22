import 'dart:async';

import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';

abstract class LocalChainAlgebra {
  FutureOr<void> adopt(BlockId newHead);
  FutureOr<BlockId> get currentHead;
  Stream<BlockId> get adoptions;
  Future<BlockId?> blockIdAtHeight(Int64 height);
  Future<BlockId?> blockIdAtDepth(Int64 height);
}
