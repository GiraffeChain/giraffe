import 'dart:async';

import 'package:blockchain/common/utils.dart';
import 'package:blockchain/consensus/utils.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class ChainSelection {
  /**
   * Selects the "better" of the two block IDs
   */
  Future<BlockId> select(BlockId a, BlockId b);
}

class ChainSelectionImpl extends ChainSelection {
  final Future<SlotData> Function(BlockId) fetchSlotData;

  ChainSelectionImpl(this.fetchSlotData);

  @override
  Future<BlockId> select(BlockId a, BlockId b) async {
    // TODO: Density chain selection
    final slotDataA = await fetchSlotData(a);
    final slotDataB = await fetchSlotData(b);
    if (slotDataA.height > slotDataB.height)
      return a;
    else if (slotDataB.height > slotDataA.height)
      return b;
    else if (slotDataA.slotId.slot < slotDataB.slotId.slot)
      return a;
    else if (slotDataB.slotId.slot < slotDataA.slotId.slot)
      return b;
    else if (slotDataA.rho.rhoTestHash.toBigInt >
        slotDataB.rho.rhoTestHash.toBigInt)
      return a;
    else
      return b;
  }
}
