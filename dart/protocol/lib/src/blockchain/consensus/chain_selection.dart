import 'package:fixnum/fixnum.dart';
import 'package:giraffe_protocol/src/blockchain/codecs.dart';
import 'package:giraffe_sdk/sdk.dart';

abstract class ChainSelection {
  Future<ChainSelectionOutcome> compare(
      BlockHeader headerX,
      BlockHeader headerY,
      BlockHeader commonAncestor,
      Future<BlockHeader?> Function(Int64) headerAtHeightA,
      Future<BlockHeader?> Function(Int64) headerAtHeightB);
}

enum ChainSelectionOutcome {
  xStandard,
  yStandard,
  xDensity,
  yDensity;

  bool get isX =>
      this == ChainSelectionOutcome.xStandard ||
      this == ChainSelectionOutcome.xDensity;
  bool get isY =>
      this == ChainSelectionOutcome.yStandard ||
      this == ChainSelectionOutcome.yDensity;
}

class ChainSelectionImpl extends ChainSelection {
  final Int64 kLookback;
  final Int64 sWindow;

  ChainSelectionImpl({required this.kLookback, required this.sWindow});

  @override
  Future<ChainSelectionOutcome> compare(
      BlockHeader headerX,
      BlockHeader headerY,
      BlockHeader commonAncestor,
      Future<BlockHeader?> Function(Int64 p1) headerAtHeightA,
      Future<BlockHeader?> Function(Int64 p1) headerAtHeightB) async {
    if (headerX.id == headerY.id) {
      return ChainSelectionOutcome.xStandard;
    } else if (headerX.id == commonAncestor.id) {
      return ChainSelectionOutcome.yStandard;
    } else if (headerX.height - commonAncestor.height <= kLookback &&
        headerY.height - commonAncestor.height <= kLookback) {
      return standardOrderOutcome(headerX, headerY);
    } else {
      return densityOrderOutcome(
          headerX, headerY, commonAncestor, headerAtHeightA, headerAtHeightB);
    }
  }

  Future<ChainSelectionOutcome> standardOrderOutcome(
      BlockHeader x, BlockHeader y) async {
    if (x.height > y.height) {
      return ChainSelectionOutcome.xStandard;
    } else if (x.height < y.height) {
      return ChainSelectionOutcome.yStandard;
    } else if (x.slot > y.slot) {
      return ChainSelectionOutcome.xStandard;
    } else if (x.slot < y.slot) {
      return ChainSelectionOutcome.yStandard;
    } else {
      // TODO: rhoTestHash tie-breaker
      return ChainSelectionOutcome.xStandard;
    }
  }

  Future<ChainSelectionOutcome> densityOrderOutcome(
      BlockHeader x,
      BlockHeader y,
      BlockHeader commonAncestor,
      Future<BlockHeader?> Function(Int64 p1) headerAtHeightA,
      Future<BlockHeader?> Function(Int64 p1) headerAtHeightB) async {
    BlockHeader xDensityBoundaryBlock = commonAncestor;
    while (true) {
      final next =
          await headerAtHeightA(xDensityBoundaryBlock.height + Int64.ONE);
      if (next == null) break;
      if (next.slot - commonAncestor.slot < sWindow) {
        xDensityBoundaryBlock = next;
      } else {
        break;
      }
    }
    final yAtXBoundary = await headerAtHeightB(xDensityBoundaryBlock.height);
    if (yAtXBoundary == null) {
      return ChainSelectionOutcome.xDensity;
    } else if (yAtXBoundary.slot > xDensityBoundaryBlock.slot) {
      return ChainSelectionOutcome.yDensity;
    } else {
      return standardOrderOutcome(xDensityBoundaryBlock, yAtXBoundary);
    }
  }
}
