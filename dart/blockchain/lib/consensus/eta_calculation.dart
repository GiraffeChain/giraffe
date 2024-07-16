import 'dart:typed_data';

import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/clock.dart';
import 'package:blockchain/common/utils.dart';
import 'package:blockchain/common/models/common.dart';
import 'package:blockchain/consensus/utils.dart';
import 'package:logging/logging.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

import 'package:fixnum/fixnum.dart';
import 'package:hashlib/hashlib.dart';
import 'package:quiver/cache.dart';

abstract class EtaCalculation {
  Future<Eta> etaToBe(SlotId parentSlotId, Int64 childSlot);
}

class EtaCalculationImpl extends EtaCalculation {
  final Future<BlockHeader> Function(BlockId) fetchHeader;
  final Clock clock;
  final Eta genesisEta;

  EtaCalculationImpl(this.fetchHeader, this.clock, this.genesisEta);

  final log = Logger("EtaCalculation");

  final cache = MapCache<BlockId, Eta>.lru(maximumSize: 32);

  @override
  Future<Eta> etaToBe(SlotId parentSlotId, Int64 childSlot) async {
    if (clock.epochOfSlot(childSlot) == Int64.ZERO) return genesisEta;
    final parentEpoch = clock.epochOfSlot(parentSlotId.slot);
    final childEpoch = clock.epochOfSlot(childSlot);
    final parentHeader = await fetchHeader(parentSlotId.blockId);
    if (parentEpoch == childEpoch)
      return parentHeader.eligibilityCertificate.eta.decodeBase58;
    else if (childEpoch - parentEpoch > 1)
      throw Exception("Empty Epoch");
    else
      return _calculate(await _locateTwoThirdsBest(parentHeader));
  }

  _locateTwoThirdsBest(BlockHeader from) async {
    if (_isWithinTwoThirds(from))
      return from;
    else
      return _locateTwoThirdsBest(await fetchHeader(from.parentHeaderId));
  }

  _isWithinTwoThirds(BlockHeader from) =>
      from.slotId.slot % clock.slotsPerEpoch <= (clock.slotsPerEpoch * 2 ~/ 3);

  Future<Eta> _calculate(BlockHeader twoThirdsBest) async =>
      (await cache.get(twoThirdsBest.id, ifAbsent: (_) async {
        final epoch = clock.epochOfSlot(twoThirdsBest.slotId.slot);
        final epochRange = clock.epochRange(epoch);
        final rhoValues = <Uint8List>[];
        BlockHeader currentHeader = twoThirdsBest;
        while (currentHeader.parentSlot >= epochRange.$1) {
          rhoValues.insert(0, await currentHeader.rho);
          currentHeader = await fetchHeader(currentHeader.parentHeaderId);
        }
        return _calculateFromValues(
            twoThirdsBest.eligibilityCertificate.eta.decodeBase58,
            epoch + 1,
            rhoValues);
      }))!;

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
      ..addAll(epoch.toBytesBigEndian());
    rhoNonceHashValues.forEach(bytes.addAll);

    return blake2b256.convert(bytes).bytes;
  }
}
