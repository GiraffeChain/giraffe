import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';

abstract class BlockPackerAlgebra {
  Future<Iterative<FullBlockBody>> improvePackedBlock(
    BlockId parentBlockId,
    Int64 height,
    Int64 slot,
  );
}

typedef Iterative<E> = Future<E?> Function(E);
