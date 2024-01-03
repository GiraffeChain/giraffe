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
  final Future<BlockHeader> Function(BlockId) fetchHeader;

  ChainSelectionImpl(this.fetchHeader);

  @override
  Future<BlockId> select(BlockId a, BlockId b) async {
    // TODO: Density chain selection
    final headerA = await fetchHeader(a);
    final headerB = await fetchHeader(b);
    if (headerA.height > headerB.height)
      return a;
    else if (headerB.height > headerA.height)
      return b;
    else if (headerA.slotId.slot < headerB.slotId.slot)
      return a;
    else if (headerB.slotId.slot < headerA.slotId.slot)
      return b;
    else if ((await headerA.rho).rhoTestHash.toBigInt >
        (await headerB.rho).rhoTestHash.toBigInt)
      return a;
    else
      return b;
  }
}
