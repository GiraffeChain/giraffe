import 'package:blockchain/common/models/common.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

import 'package:fixnum/fixnum.dart';

abstract class EtaCalculation {
  Future<Eta> etaToBe(SlotId parentSlotId, Int64 childSlot);
}
