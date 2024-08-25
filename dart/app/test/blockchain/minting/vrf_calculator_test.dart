import 'dart:typed_data';

import 'package:blockchain_app/blockchain/common/clock.dart';
import 'package:blockchain_app/blockchain/consensus/leader_election_validation.dart';
import 'package:blockchain_app/blockchain/minting/vrf_calculator.dart';
import 'package:blockchain_sdk/sdk.dart';
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
          "bc31a2fb46995ffbe4b316176407f57378e2f3d7fee57d228a811194361d8e7040c9d15575d7a2e75506ffe1a47d772168b071a99d2e85511730e9c21397a1cea0e7fa4bd161e6d5185a94a665dd190d");
      expect(proof.sameElements(expectedProof), true);
    });
  });
}
