import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/clock.dart';
import 'package:blockchain/common/models/common.dart';
import 'package:blockchain/common/models/unsigned.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain/consensus/staker_tracker.dart';
import 'package:blockchain/consensus/eta_calculation.dart';
import 'package:blockchain/consensus/leader_election_validation.dart';
import 'package:blockchain/consensus/utils.dart';
import 'package:blockchain/crypto/ed25519.dart';
import 'package:blockchain/crypto/impl/kes_product.dart';
import 'package:blockchain/minting/models/vrf_hit.dart';
import 'package:blockchain/minting/secure_store.dart';
import 'package:blockchain/minting/vrf_calculator.dart';
import 'package:fixnum/fixnum.dart';
import 'package:logging/logging.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain/crypto/kes.dart';
import 'package:rational/rational.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:convert/convert.dart';

abstract class Staking {
  TransactionOutputReference get account;
  Future<VrfHit?> elect(SlotId parentSlotId, Int64 slot);
  Future<BlockHeader?> certifyBlock(
      SlotId parentSlotId,
      Int64 slot,
      UnsignedBlockHeader Function(PartialOperationalCertificate)
          unsignedBlockBuilder);
}

class StakingImpl extends Staking {
  final Int64 operationalPeriodLength;
  final Int64 activationOperationalPeriod;
  final TransactionOutputReference account;
  final SecureStore secureStore;
  final List<int> vkVrf;
  final StakerTracker stakerTracker;
  final EtaCalculation etaCalculation;
  final VrfCalculator vrfCalculator;
  final LeaderElection leaderElection;

  Int64? currentOperationalPeriod;
  Map<Int64, Future<OperationalKeyOut>>? currentKeyCache;

  final log = Logger("staking");

  StakingImpl(
    this.operationalPeriodLength,
    this.activationOperationalPeriod,
    this.account,
    this.secureStore,
    this.vkVrf,
    this.stakerTracker,
    this.etaCalculation,
    this.vrfCalculator,
    this.leaderElection,
  );

  static Resource<StakingImpl> make(
    SlotId parentSlotId,
    Int64 operationalPeriodLength,
    Int64 activationOperationalPeriod,
    TransactionOutputReference account,
    List<int> vkVrf,
    SecureStore secureStore,
    Clock clock,
    VrfCalculator vrfCalculator,
    EtaCalculation etaCalculation,
    StakerTracker stakerTracker,
    LeaderElection leaderElection,
  ) =>
      Resource.pure(StakingImpl(
        operationalPeriodLength,
        activationOperationalPeriod,
        account,
        secureStore,
        vkVrf,
        stakerTracker,
        etaCalculation,
        vrfCalculator,
        leaderElection,
      ));

  @override
  Future<BlockHeader?> certifyBlock(
      SlotId parentSlotId,
      Int64 slot,
      UnsignedBlockHeader Function(PartialOperationalCertificate)
          unsignedBlockBuilder) async {
    final operationalKeyOutOpt =
        await _operationalKeyForSlot(slot, parentSlotId);
    if (operationalKeyOutOpt != null) {
      final partialCertificate = PartialOperationalCertificate(
        operationalKeyOutOpt.parentVK,
        operationalKeyOutOpt.parentSignature,
        operationalKeyOutOpt.childKeyPair.vk,
      );
      final unsignedHeader = unsignedBlockBuilder(partialCertificate);
      final List<int> messageToSign = unsignedHeader.signableBytes;
      final cryptoKeyPair = await Ed25519KeyPair(
          operationalKeyOutOpt.childKeyPair.sk,
          operationalKeyOutOpt.childKeyPair.vk);
      final operationalCertificate = OperationalCertificate()
        ..parentVK = operationalKeyOutOpt.parentVK
        ..parentSignature = operationalKeyOutOpt.parentSignature
        ..childVK = operationalKeyOutOpt.childKeyPair.vk
        ..childSignature = await ed25519.signKeyPair(
          messageToSign,
          cryptoKeyPair,
        );
      final header = BlockHeader()
        ..parentHeaderId = unsignedHeader.parentHeaderId
        ..parentSlot = unsignedHeader.parentSlot
        ..txRoot = unsignedHeader.txRoot
        ..timestamp = unsignedHeader.timestamp
        ..height = unsignedHeader.height
        ..slot = unsignedHeader.slot
        ..eligibilityCertificate = unsignedHeader.eligibilityCertificate
        ..operationalCertificate = operationalCertificate
        ..metadata = unsignedHeader.metadata
        ..account = unsignedHeader.account;
      return header;
    }
    return null;
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
      final cert = EligibilityCertificate()
        ..vrfSig = testProof
        ..vrfVK = vkVrf
        ..thresholdEvidence = evidence
        ..eta = eta;
      return VrfHit(cert, slot, threshold);
    }
    return null;
  }

  Future<OperationalKeyOut?> _operationalKeyForSlot(
      Int64 slot, SlotId parentSlotId) async {
    final operationalPeriod = slot ~/ operationalPeriodLength;
    if (operationalPeriod == currentOperationalPeriod)
      return currentKeyCache?[slot];
    final relativeStake = await stakerTracker.operatorRelativeStake(
        parentSlotId.blockId, slot, account);
    if (relativeStake == null) return null;
    final newKeys = await _consumeEvolvePersist(
        (operationalPeriod - activationOperationalPeriod).toInt(),
        (t) => _prepareOperationalPeriodKeys(
            t, slot, parentSlotId, relativeStake));
    currentOperationalPeriod = operationalPeriod;
    currentKeyCache = newKeys;
    return newKeys?[slot];
  }

  Future<T?> _consumeEvolvePersist<T>(
      int timeStep, Future<T> Function(SecretKeyKesProduct) use) async {
    final fileNames = await secureStore.list();
    if (fileNames.length != 1)
      throw Exception("SecureStore contained invalid number of keys");
    final fileName = fileNames.first;
    log.info("Consuming key id=$fileName");
    final diskKeyBytes = await secureStore.consume(fileName);
    if (diskKeyBytes == null) return null;
    final SecretKeyKesProduct diskKey =
        SecretKeyKesProduct.decode(Uint8List.fromList(diskKeyBytes));
    final latest = await kesProduct.getCurrentStep(diskKey);
    SecretKeyKesProduct? currentPeriodKey;
    if (latest == timeStep)
      currentPeriodKey = diskKey;
    else if (latest > timeStep) {
      log.info(
          "Persisted key timeStep=$latest is greater than current timeStep=$timeStep." +
              "  Re-persisting original key.");
      secureStore.write(fileName, diskKeyBytes);
    } else {
      currentPeriodKey = await kesProduct.update(diskKey, timeStep);
    }

    if (currentPeriodKey == null) return null;
    final res = await use(currentPeriodKey);
    final nextTimeStep = timeStep + 1;
    log.info("Updating next key idx=$nextTimeStep");
    final updated = await kesProduct.update(currentPeriodKey, nextTimeStep);
    log.info("Saving next key idx=$nextTimeStep");
    await secureStore.write("k", updated.encode);
    log.info("Saved next key idx=$nextTimeStep");
    return res;
  }

  Future<Map<Int64, Future<OperationalKeyOut>>> _prepareOperationalPeriodKeys(
      SecretKeyKesProduct kesParent,
      Slot fromSlot,
      SlotId parentSlotId,
      Rational relativeStake) async {
    final eta = await etaCalculation.etaToBe(parentSlotId, fromSlot);
    final operationalPeriod = fromSlot ~/ operationalPeriodLength;

    final operationalPeriodSlotMin =
        operationalPeriod * operationalPeriodLength;
    final operationalPeriodSlotMax =
        (operationalPeriod + 1) * operationalPeriodLength;
    final ineligibleSlots = await vrfCalculator.ineligibleSlots(
      eta,
      (operationalPeriodSlotMin, operationalPeriodSlotMax),
      relativeStake,
    );
    final slots = List.generate(
            (operationalPeriodLength - (fromSlot % operationalPeriodLength))
                .toInt(),
            (i) => fromSlot + i)
        .where((s) => !ineligibleSlots.contains(s))
        .toList();
    log.info("Preparing linear keys. count=${slots.length}");

    final parentVK = await kesProduct.generateVerificationKey(kesParent);

    forSlot(Slot slot) async {
      final childKeyPair = await ed25519.generateKeyPair();
      final parentSignature = await kesProduct.sign(
        kesParent,
        childKeyPair.vk + slot.immutableBytes,
      );
      return OperationalKeyOut(slot, childKeyPair, parentSignature, parentVK);
    }

    return Map.fromEntries(slots.map((slot) => MapEntry(slot, forSlot(slot))));
  }
}

class OperationalKeyOut {
  final Int64 slot;
  final Ed25519KeyPair childKeyPair;
  final SignatureKesProduct parentSignature;
  final VerificationKeyKesProduct parentVK;

  OperationalKeyOut(
      this.slot, this.childKeyPair, this.parentSignature, this.parentVK);
}
