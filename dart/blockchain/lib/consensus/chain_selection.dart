import 'dart:async';

import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/utils.dart';
import 'package:blockchain/consensus/models/protocol_settings.dart';
import 'package:blockchain/consensus/utils.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';

class ChainSelection {
  final ProtocolSettings protocolSettings;

  ChainSelection({required this.protocolSettings});
  /**
   * Selects the "better" of the two blocks
   */
  Future<ChainSelectionOutcome> select(
    BlockHeader headerA,
    BlockHeader headerB,
    BlockHeader commonAncestor,
    Future<BlockHeader?> Function(Int64) headerAtHeightA,
    Future<BlockHeader?> Function(Int64) headerAtHeightB,
  ) async {
    if (headerA.height - commonAncestor.height <=
            protocolSettings.chainSelectionKLookback &&
        headerB.height - commonAncestor.height <=
            protocolSettings.chainSelectionKLookback)
      return maxValidBg(headerA, headerB);
    final aDensityBoundary =
        await densityBoundaryBlock(commonAncestor, headerAtHeightA);
    final bAtA = await headerAtHeightB(aDensityBoundary.height);
    if (bAtA == null ||
        bAtA.slot >
            commonAncestor.slot + protocolSettings.chainSelectionSWindow)
      return DensitySelectionOutcome(id: headerA.id);
    else {
      final bAtA1 = await headerAtHeightB(aDensityBoundary.height + 1);
      if (bAtA1 == null ||
          bAtA1.slot >
              commonAncestor.slot + protocolSettings.chainSelectionSWindow) {
        // Tie
        final tieBreaker = await maxValidBg(aDensityBoundary, bAtA1!);
        if (tieBreaker.id == aDensityBoundary.id) {
          return DensitySelectionOutcome(id: headerA.id);
        } else {
          return DensitySelectionOutcome(id: headerB.id);
        }
      } else {
        return DensitySelectionOutcome(id: headerB.id);
      }
    }
  }

  // Calculates the latest block within the protocol's sWindow
  Future<BlockHeader> densityBoundaryBlock(BlockHeader commonAncestor,
      Future<BlockHeader?> Function(Int64) headerAtHeight) async {
    BlockHeader h = commonAncestor;
    while (true) {
      final next = await headerAtHeight(h.height + 1);
      if (next == null) break;
      if (next.slot - commonAncestor.slot >=
          protocolSettings.chainSelectionSWindow) break;
      h = next;
    }
    return h;
  }

  Future<ChainSelectionOutcome> maxValidBg(
      BlockHeader headerA, BlockHeader headerB) async {
    late final BlockId id;
    if (headerA.height > headerB.height)
      id = headerA.id;
    else if (headerB.height > headerA.height)
      id = headerB.id;
    else if (headerA.slotId.slot < headerB.slotId.slot)
      id = headerA.id;
    else if (headerB.slotId.slot < headerA.slotId.slot)
      id = headerB.id;
    else if ((await headerA.rho).rhoTestHash.toBigInt >
        (await headerB.rho).rhoTestHash.toBigInt)
      id = headerA.id;
    else
      id = headerB.id;
    return StandardSelectionOutcome(id: id);
  }
}

sealed class ChainSelectionOutcome {
  final BlockId id;

  ChainSelectionOutcome({required this.id});
}

class StandardSelectionOutcome extends ChainSelectionOutcome {
  StandardSelectionOutcome({required super.id});
}

class DensitySelectionOutcome extends ChainSelectionOutcome {
  DensitySelectionOutcome({required super.id});
}
