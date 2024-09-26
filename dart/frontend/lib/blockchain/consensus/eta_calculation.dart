import 'package:giraffe_sdk/sdk.dart';

import '../common/models/common.dart';

import 'package:fixnum/fixnum.dart';

abstract class EtaCalculation {
  Future<Eta> etaToBe(SlotId parentSlotId, Int64 childSlot);
}

class EtaCalculationForStakerSupportRpc extends EtaCalculation {
  final BlockchainClient client;

  EtaCalculationForStakerSupportRpc({required this.client});

  @override
  Future<Eta> etaToBe(SlotId parentSlotId, Int64 childSlot) =>
      client.calculateEta(
        parentSlotId.blockId,
        childSlot,
      );
}
