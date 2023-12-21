import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain/common/models/common.dart';
import 'package:fixnum/fixnum.dart';

abstract class EtaCalculationAlgebra {
  Future<Eta> etaToBe(SlotId parentSlotId, Int64 childSlot);
}
