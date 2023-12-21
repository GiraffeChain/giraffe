import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';

class BodyValidationContext {
  final BlockId parentHeaderId;
  final Int64 height;
  final Int64 slot;

  BodyValidationContext(
    this.parentHeaderId,
    this.height,
    this.slot,
  );
}
