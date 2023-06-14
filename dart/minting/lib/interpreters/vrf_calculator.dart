import 'package:blockchain_codecs/codecs.dart';
import 'package:blockchain_common/algebras/clock_algebra.dart';
import 'package:blockchain_common/models/common.dart';
import 'package:blockchain_consensus/algebras/leader_election_validation_algebra.dart';
import 'package:blockchain_consensus/models/vrf_config.dart';
import 'package:blockchain_consensus/models/vrf_argument.dart';
import 'package:blockchain_crypto/ed25519vrf.dart';
import 'package:blockchain_minting/algebras/vrf_calculator_algebra.dart';
import 'package:fpdart/src/tuple.dart';
import 'package:fixnum/fixnum.dart';
import 'package:logging/logging.dart';
import 'package:rational/rational.dart';

class VrfCalculator extends VrfCalculatorAlgebra {
  final List<int> skVrf;
  final ClockAlgebra clock;
  final LeaderElectionValidationAlgebra leaderElectionValidation;
  final VrfConfig vrfConfig;

  final log = Logger("VrfCalculator");

  Map<Tuple2<List<int>, Int64>, List<int>> _vrfProofsCache = {};
  Map<Tuple2<List<int>, Int64>, List<int>> _rhosCache = {};

  VrfCalculator(
      this.skVrf, this.clock, this.leaderElectionValidation, this.vrfConfig);

  @override
  Future<List<Int64>> ineligibleSlots(List<int> eta,
      Tuple2<Int64, Int64> slotRange, Rational relativeStake) async {
    var minSlot = slotRange.first;
    var maxSlot = slotRange.second;

    log.info(
      "Computing ineligible slots for" +
          " eta=${eta.show}" +
          " range=$minSlot..$maxSlot",
    );
    final threshold = await leaderElectionValidation.getThreshold(
        relativeStake, Int64(vrfConfig.lddCutoff));
    final leaderCalculations = <Slot>[];
    forSlot(Int64 slot) async {
      final rho = await rhoForSlot(slot, eta);
      final isLeader = await leaderElectionValidation.isSlotLeaderForThreshold(
          threshold, rho);
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
    final key = Tuple2(eta, slot);
    if (!_vrfProofsCache.containsKey(key)) {
      final arg = VrfArgument(eta, slot);
      final message = arg.signableBytes;
      final result = await ed25519Vrf.sign(skVrf, message);

      _vrfProofsCache[key] = result;
      return result;
    }
    return _vrfProofsCache[key]!;
  }

  @override
  Future<List<int>> rhoForSlot(Int64 slot, List<int> eta) async {
    final key = Tuple2(eta, slot);
    if (!_rhosCache.containsKey(key)) {
      final proof = await proofForSlot(slot, eta);
      final rho = await ed25519Vrf.proofToHash(proof);
      _rhosCache[key] = rho;
      return rho;
    }
    return _rhosCache[key]!;
  }
}
