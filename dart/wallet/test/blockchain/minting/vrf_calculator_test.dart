import 'dart:typed_data';

import 'package:giraffe_wallet/blockchain/common/clock.dart';
import 'package:giraffe_wallet/blockchain/consensus/leader_election_validation.dart';
import 'package:giraffe_wallet/blockchain/minting/vrf_calculator.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:convert/convert.dart';
import 'package:test/test.dart';
import 'package:mockito/annotations.dart';
import 'package:fixnum/fixnum.dart';

@GenerateNiceMocks([MockSpec<Clock>(), MockSpec<LeaderElection>()])
import 'vrf_calculator_test.mocks.dart';

void main() {
  group("VrfCalculator", () {
    test("proofForSlot", () async {
      final skVrf = Int8List(32);
      final config = ProtocolSettings.defaultSettings
          .mergeFromMap({"vrf-ldd-cutoff": "15"});
      final calculator =
          VrfCalculatorImpl(skVrf, MockClock(), MockLeaderElection(), config);

      final eta = Int8List(32);
      final proof = await calculator.proofForSlot(Int64(10), eta);
      final expectedProof = hex.decode(
          "d557aba5b5ded5ee36e193484496ab6cd01ff71862628485bba4e48e3fd4adca6022bbe5ce1ee1b2a206921464fd162f5294175cdf608993303f81d7da1b7f5f42dc0928a75d3cab761686d190bc1606");
      expect(proof.sameElements(expectedProof), true);
    });
  });
}
