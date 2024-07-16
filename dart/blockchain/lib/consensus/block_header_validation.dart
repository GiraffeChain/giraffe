import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/clock.dart';
import 'package:blockchain/common/utils.dart';
import 'package:blockchain/consensus/staker_tracker.dart';
import 'package:blockchain/consensus/eta_calculation.dart';
import 'package:blockchain/consensus/leader_election_validation.dart';
import 'package:blockchain/consensus/models/vrf_argument.dart';
import 'package:blockchain/consensus/utils.dart';
import 'package:blockchain/crypto/ed25519.dart';
import 'package:blockchain/crypto/ed25519vrf.dart';
import 'package:blockchain/crypto/kes.dart';
import 'package:blockchain/crypto/utils.dart';
import 'package:fixnum/fixnum.dart';
import 'package:rational/rational.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:ribs_core/ribs_core.dart';

abstract class BlockHeaderValidation {
  /**
   * Indicates if the claimed child is a valid descendent of the parent
   */
  Future<List<String>> validate(BlockHeader header);
}

class BlockHeaderValidationImpl extends BlockHeaderValidation {
  final BlockId genesisBlockId;
  final EtaCalculation etaInterpreter;
  final StakerTracker consensusValidationState;
  final LeaderElection leaderElectionValidation;
  final Clock clock;
  final Future<BlockHeader> Function(BlockId) fetchHeader;

  static final _maximumSlotDesync = Int64(5);

  BlockHeaderValidationImpl(
      this.genesisBlockId,
      this.etaInterpreter,
      this.consensusValidationState,
      this.leaderElectionValidation,
      this.clock,
      this.fetchHeader);

  @override
  Future<List<String>> validate(BlockHeader header) async {
    if (header.id == genesisBlockId) return [];
    final parent = await fetchHeader(header.parentHeaderId);
    final List<String> errors = [];

    errors.addAll(_statelessVerification(header, parent));
    if (errors.isNotEmpty) return errors;

    errors.addAll(_timeSlotVerification(header));
    if (errors.isNotEmpty) return errors;

    errors.addAll(await _vrfVerification(header));
    if (errors.isNotEmpty) return errors;

    errors.addAll(await _kesVerification(header));
    if (errors.isNotEmpty) return errors;

    errors.addAll(await _registrationVerification(header));
    if (errors.isNotEmpty) return errors;

    final vrfThresholdOrErrors = await _vrfThresholdFor(header);

    if (vrfThresholdOrErrors.isLeft)
      return vrfThresholdOrErrors.swap().toOption().toNullable()!;

    final vrfThreshold = vrfThresholdOrErrors.toOption().toNullable()!;

    errors.addAll(_vrfThresholdVerification(header, vrfThreshold));
    if (errors.isNotEmpty) return errors;

    errors.addAll(await _eligibilityVerification(header, vrfThreshold));
    if (errors.isNotEmpty) return errors;

    return [];
  }

  List<String> _statelessVerification(BlockHeader child, BlockHeader parent) {
    if (child.slot <= parent.slot) return ["NonForwardSlot"];
    if (child.timestamp <= parent.timestamp) return ["NonForwardTimestamp"];
    if (child.height != parent.height + 1) return ["NonForwardHeight"];
    return [];
  }

  List<String> _timeSlotVerification(BlockHeader header) {
    if (clock.timestampToSlot(header.timestamp) != header.slot)
      return ["TimestampSlotMismatch"];
    if (header.slot > (clock.globalSlot + _maximumSlotDesync))
      return ["SlotClockDesync"];
    return [];
  }

  Future<List<String>> _vrfVerification(BlockHeader header) async {
    final expectedEta = await etaInterpreter.etaToBe(
        SlotId()
          ..slot = header.parentSlot
          ..blockId = header.parentHeaderId,
        header.slot);
    if (!expectedEta
        .sameElements(header.eligibilityCertificate.eta.decodeBase58))
      return ["InvalidEligibilityCertificateEta"];
    final signatureVerification = await ed25519Vrf.verify(
      header.eligibilityCertificate.vrfSig.decodeBase58,
      VrfArgument(expectedEta, header.slot).signableBytes,
      header.eligibilityCertificate.vrfVK.decodeBase58,
    );
    if (!signatureVerification) return ["InvalidEligibilityCertificate"];
    return [];
  }

  Future<List<String>> _kesVerification(BlockHeader header) async {
    final parentCommitmentVerification = await kesProduct.verify(
      header.operationalCertificate.parentSignature,
      header.operationalCertificate.childVK.decodeBase58 +
          header.slot.immutableBytes,
      header.operationalCertificate.parentVK,
    );
    if (!parentCommitmentVerification)
      return ["InvalidOperationalParentSignature"];
    final childSignatureResult = await ed25519.verify(
      header.operationalCertificate.childSignature.decodeBase58,
      header.unsigned.signableBytes,
      header.operationalCertificate.childVK.decodeBase58,
    );
    if (!childSignatureResult) return ["InvalidBlockProof"];
    return [];
  }

  Future<List<String>> _registrationVerification(BlockHeader header) async {
    final staker = await consensusValidationState.staker(
        await header.id, header.slot, header.account);
    if (staker == null) return ["Unregistered"];
    final message = await (header.eligibilityCertificate.vrfVK.decodeBase58 +
            staker.registration.stakingAddress.value.decodeBase58)
        .hash256;

    final verificationResult = await kesProduct.verify(
        staker.registration.signature,
        message,
        VerificationKeyKesProduct()
          ..value = header.operationalCertificate.parentVK.value
          ..step = 0);
    if (!verificationResult) return ["RegistrationCommitmentMismatch"];
    return [];
  }

  Future<Either<List<String>, Rational>> _vrfThresholdFor(
      BlockHeader header) async {
    final relativeStake = await consensusValidationState.operatorRelativeStake(
        await header.id, header.slot, header.account);
    if (relativeStake == null) return Left(["Unregistered"]);
    final threshold = await leaderElectionValidation.getThreshold(
        relativeStake, header.slot - header.parentSlot);
    return Right(threshold);
  }

  List<String> _vrfThresholdVerification(
      BlockHeader header, Rational threshold) {
    final evidence = threshold.thresholdEvidence;
    if (!evidence.sameElements(
        header.eligibilityCertificate.thresholdEvidence.decodeBase58))
      return ["InvalidVrfThreshold"];
    return [];
  }

  Future<List<String>> _eligibilityVerification(
      BlockHeader header, Rational threshold) async {
    final rho = await ed25519Vrf
        .proofToHash(header.eligibilityCertificate.vrfSig.decodeBase58);
    final isSlotLeader =
        await leaderElectionValidation.isEligible(threshold, rho);
    if (!isSlotLeader) return ["Ineligible"];
    return [];
  }
}
