import '../codecs.dart';
import '../common/models/unsigned.dart';
import '../consensus/staker_tracker.dart';
import '../consensus/eta_calculation.dart';
import '../consensus/leader_election_validation.dart';
import '../consensus/utils.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'models/vrf_hit.dart';
import 'vrf_calculator.dart';
import 'package:fixnum/fixnum.dart';
import 'package:logging/logging.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'dart:async';

abstract class Staking {
  TransactionOutputReference get account;
  Future<VrfHit?> elect(SlotId parentSlotId, Int64 slot);
  Future<BlockHeader> certifyBlock(
      SlotId parentSlotId, Int64 slot, UnsignedBlockHeader unsignedHeader);
}

class StakingImpl extends Staking {
  @override
  final TransactionOutputReference account;
  final List<int> vkVrf;
  final List<int> skOperator;
  final StakerTracker stakerTracker;
  final EtaCalculation etaCalculation;
  final VrfCalculator vrfCalculator;
  final LeaderElection leaderElection;

  final log = Logger("staking");

  StakingImpl(
    this.account,
    this.vkVrf,
    this.skOperator,
    this.stakerTracker,
    this.etaCalculation,
    this.vrfCalculator,
    this.leaderElection,
  );

  @override
  Future<BlockHeader> certifyBlock(SlotId parentSlotId, Int64 slot,
      UnsignedBlockHeader unsignedHeader) async {
    final List<int> messageToSign = unsignedHeader.signableBytes;
    final signature = await ed25519.sign(messageToSign, skOperator);
    final stakerCertificate = StakerCertificate(
      blockSignature: signature.base58,
      vrfSignature: unsignedHeader.partialStakerCertificate.vrfSignature,
      vrfVK: unsignedHeader.partialStakerCertificate.vrfVK,
      thresholdEvidence:
          unsignedHeader.partialStakerCertificate.thresholdEvidence,
      eta: unsignedHeader.partialStakerCertificate.eta,
    );
    final header = BlockHeader()
      ..parentHeaderId = unsignedHeader.parentHeaderId
      ..parentSlot = unsignedHeader.parentSlot
      ..txRoot = unsignedHeader.txRoot
      ..timestamp = unsignedHeader.timestamp
      ..height = unsignedHeader.height
      ..slot = unsignedHeader.slot
      ..stakerCertificate = stakerCertificate
      ..account = unsignedHeader.account;
    return header;
  }

  @override
  Future<VrfHit?> elect(SlotId parentSlotId, Int64 slot) async {
    final eta = await etaCalculation.etaToBe(parentSlotId, slot);
    final relativeStake = await stakerTracker.operatorRelativeStake(
        parentSlotId.blockId, slot, account);
    if (relativeStake == null) return null;
    final threshold = await leaderElection.getThreshold(
        relativeStake, slot - parentSlotId.slot);
    final rho = await vrfCalculator.rhoForSlot(slot, eta);
    final isLeader = await leaderElection.isEligible(threshold, rho);
    log.fine("Staking leader election test result=$isLeader slot=$slot");
    if (isLeader) {
      final evidence = threshold.thresholdEvidence;
      final testProof = await vrfCalculator.proofForSlot(slot, eta);
      final cert = PartialStakerCertificate(
          vrfSignature: testProof.base58,
          vrfVK: vkVrf.base58,
          thresholdEvidence: evidence.base58,
          eta: eta.base58);
      return VrfHit(cert, slot, threshold);
    }
    return null;
  }
}
