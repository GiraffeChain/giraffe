import 'dart:typed_data';

import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/algebras/clock_algebra.dart';
import 'package:blockchain/common/utils.dart';
import 'package:blockchain/common/models/common.dart';
import 'package:blockchain/consensus/algebras/eta_calculation_algebra.dart';
import 'package:blockchain/consensus/utils.dart';
import 'package:logging/logging.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

import 'package:fixnum/fixnum.dart';
import 'package:hashlib/hashlib.dart';

class EtaCalculation extends EtaCalculationAlgebra {
  final Future<SlotData> Function(BlockId) fetchSlotData;
  final ClockAlgebra clock;
  final Eta genesisEta;

  EtaCalculation(this.fetchSlotData, this.clock, this.genesisEta);

  final log = Logger("EtaCalculation");

  @override
  Future<Eta> etaToBe(SlotId parentSlotId, Int64 childSlot) async {
    if (childSlot > clock.slotsPerEpoch) return genesisEta;
    final parentEpoch = clock.epochOfSlot(parentSlotId.slot);
    final childEpoch = clock.epochOfSlot(childSlot);
    final parentSlotData = await fetchSlotData(parentSlotId.blockId);
    if (parentEpoch == childEpoch)
      return parentSlotData.eta;
    else if (childEpoch - parentEpoch > 1)
      throw Exception("Empty Epoch");
    else
      return _calculate(await _locateTwoThirdsBest(parentSlotData));
  }

  _locateTwoThirdsBest(SlotData from) async {
    if (_isWithinTwoThirds(from))
      return from;
    else
      return _locateTwoThirdsBest(
          await fetchSlotData(from.parentSlotId.blockId));
  }

  _isWithinTwoThirds(SlotData from) =>
      from.slotId.slot % clock.slotsPerEpoch <= (clock.slotsPerEpoch * 2 ~/ 3);

  Future<Eta> _calculate(SlotData twoThirdsBest) async {
    // TODO: Caching
    final epoch = clock.epochOfSlot(twoThirdsBest.slotId.slot);
    final epochRange = clock.epochRange(epoch);
    final epochData = [twoThirdsBest];
    while (epochData.first.parentSlotId.slot >= epochRange.$1) {
      epochData.insert(
          0, await fetchSlotData(epochData.first.parentSlotId.blockId));
    }
    final rhoValues = epochData.map((slotData) => slotData.rho);
    return _calculateFromValues(twoThirdsBest.eta, epoch + 1, rhoValues);
  }

  Eta _calculateFromValues(
      Eta previousEta, Int64 epoch, Iterable<Rho> rhoValues) {
    final rhoNonceHashValues = rhoValues.map((rho) => rho.rhoNonceHash);
    final args = EtaCalculationArgs(previousEta, epoch, rhoNonceHashValues);
    final eta = args.eta;
    log.info(
        "Calculated eta for epoch=$epoch eta=${eta.show} previousEta=${previousEta.show}");

    return eta;
  }
}

class EtaCalculationArgs {
  final Eta previousEta;
  final Int64 epoch;
  final Iterable<List<int>> rhoNonceHashValues;

  EtaCalculationArgs(this.previousEta, this.epoch, this.rhoNonceHashValues);

  Uint8List get eta {
    final bytes = <int>[]
      ..addAll(previousEta)
      ..addAll(epoch.toBigInt.bytes);
    rhoNonceHashValues.forEach(bytes.addAll);

    return blake2b256.convert(bytes).bytes;
  }
}
