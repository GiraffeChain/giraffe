import '../common/clock.dart';
import '../consensus/leader_election_validation.dart';
import 'package:giraffe_sdk/sdk.dart';
import '../consensus/models/vrf_argument.dart';
import 'package:fixnum/fixnum.dart';
import 'package:logging/logging.dart';

abstract class VrfCalculator {
  Future<List<int>> rhoForSlot(Int64 slot, List<int> eta);
  Future<List<int>> proofForSlot(Int64 slot, List<int> eta);
}

class VrfCalculatorImpl extends VrfCalculator {
  final List<int> skVrf;
  final Clock clock;
  final LeaderElection leaderElectionValidation;
  final ProtocolSettings protocolSettings;

  final log = Logger("VrfCalculator");

  final Map<VrfArgument, List<int>> _vrfProofsCache = {};
  final Map<VrfArgument, List<int>> _rhosCache = {};

  VrfCalculatorImpl(this.skVrf, this.clock, this.leaderElectionValidation,
      this.protocolSettings);

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
