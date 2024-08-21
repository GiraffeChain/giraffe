import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';

abstract class BlockPacker {
  Stream<FullBlockBody> streamed(
    BlockId parentBlockId,
    Int64 height,
    Int64 slot,
  );
}
