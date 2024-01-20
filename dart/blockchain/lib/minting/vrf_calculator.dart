import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/clock.dart';
import 'package:blockchain/common/models/common.dart';
import 'package:blockchain/consensus/leader_election_validation.dart';
import 'package:blockchain/consensus/models/protocol_settings.dart';
import 'package:blockchain/consensus/models/vrf_argument.dart';
import 'package:blockchain/crypto/ed25519vrf.dart';
import 'package:fixnum/fixnum.dart';
import 'package:logging/logging.dart';
import 'package:rational/rational.dart';

abstract class VrfCalculator {
  Future<List<int>> rhoForSlot(Int64 slot, List<int> eta);
  Future<List<int>> proofForSlot(Int64 slot, List<int> eta);
  Future<List<Int64>> ineligibleSlots(
      List<int> eta, (Int64, Int64) slotRange, Rational relativeStake);
}

class VrfCalculatorImpl extends VrfCalculator {
  final List<int> skVrf;
  final Clock clock;
  final LeaderElection leaderElectionValidation;
  final ProtocolSettings protocolSettings;

  final log = Logger("VrfCalculator");

  Map<VrfArgument, List<int>> _vrfProofsCache = {};
  Map<VrfArgument, List<int>> _rhosCache = {};

  VrfCalculatorImpl(this.skVrf, this.clock, this.leaderElectionValidation,
      this.protocolSettings);

  @override
  Future<List<Int64>> ineligibleSlots(
      List<int> eta, (Int64, Int64) slotRange, Rational relativeStake) async {
    final (minSlot, maxSlot) = slotRange;

    log.info(
      "Computing ineligible slots for" +
          " eta=${eta.show}" +
          " range=$minSlot..$maxSlot",
    );
    final threshold = await leaderElectionValidation.getThreshold(
        relativeStake, Int64(protocolSettings.vrfLddCutoff));
    final leaderCalculations = <Slot>[];
    forSlot(Int64 slot) async {
      final rho = await rhoForSlot(slot, eta);
      final isLeader =
          await leaderElectionValidation.isEligible(threshold, rho);
      if (!isLeader) {
        leaderCalculations.add(slot);
      }
    }

    await Future.wait(List.generate(
        (maxSlot - minSlot).toInt(), (i) => forSlot(minSlot + i)));
    return leaderCalculations..sort();
  }

  @override
  Future<List<int>> proofForSlot(Int64 slot, List<int> eta) async {
    final key = VrfArgument(eta, slot);
    if (!_vrfProofsCache.containsKey(key)) {
      final message = key.signableBytes;
      final result = await ed25519Vrf.sign(skVrf, message);
      final vkVrf = await ed25519Vrf.getVerificationKey(skVrf);
      assert(await ed25519Vrf.verify(result, message, vkVrf));

      _vrfProofsCache[key] = result;
      return result;
    }
    return _vrfProofsCache[key]!;
  }

  @override
  Future<List<int>> rhoForSlot(Int64 slot, List<int> eta) async {
    final key = VrfArgument(eta, slot);
    if (!_rhosCache.containsKey(key)) {
      final proof = await proofForSlot(slot, eta);
      final rho = await ed25519Vrf.proofToHash(proof);
      _rhosCache[key] = rho;
      return rho;
    }
    return _rhosCache[key]!;
  }
}
