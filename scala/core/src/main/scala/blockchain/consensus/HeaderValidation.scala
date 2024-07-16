package blockchain.consensus

import blockchain.codecs.{*, given}
import blockchain.crypto.{CryptoResources, given}
import blockchain.models.{BlockHeader, BlockId, SlotId}
import blockchain.utility.*
import blockchain.{*, given}
import cats.data.{EitherT, NonEmptyChain}
import cats.effect.{Resource, Sync}
import cats.implicits.*
import com.google.common.primitives.Longs

trait HeaderValidation[F[_]]:
  def validate(blockHeader: BlockHeader): ValidationResult[F]

object HeaderValidation:
  def make[F[_]: Sync: CryptoResources](
      genesisId: BlockId,
      etaCalculation: EtaCalculation[F],
      stakerTracker: StakerTracker[F],
      leaderElection: LeaderElection[F],
      clock: Clock[F],
      fetchHeader: BlockId => F[BlockHeader]
  ): Resource[F, HeaderValidation[F]] = Resource.pure(
    new HeaderValidationImpl[F](
      genesisId,
      etaCalculation,
      stakerTracker,
      leaderElection,
      clock,
      fetchHeader
    )
  )

class HeaderValidationImpl[F[_]: Sync: CryptoResources](
    genesisId: BlockId,
    etaCalculation: EtaCalculation[F],
    stakerTracker: StakerTracker[F],
    leaderElection: LeaderElection[F],
    clock: Clock[F],
    fetchHeader: BlockId => F[BlockHeader]
) extends HeaderValidation[F]:
  override def validate(header: BlockHeader): ValidationResult[F] =
    if (header.id == genesisId) EitherT.pure(())
    else
      for {
        parent <- EitherT.liftF(fetchHeader(header.parentHeaderId))
        _ <- statelessVerification(header, parent)
        _ <- timeSlotVerification(header)
        _ <- vrfVerification(header)
        _ <- kesVerification(header)
        _ <- registrationVerification(header)
        threshold <- vrfThresholdFor(header, parent)
        _ <- vrfThresholdVerification(header, threshold)
        _ <- eligibilityVerification(header, threshold)
      } yield ()

  private[consensus] def statelessVerification(child: BlockHeader, parent: BlockHeader) =
    for {
      _ <- EitherT.cond[F](child.slot > parent.slot, (), NonEmptyChain("Non-Forward Slot"))
      _ <- EitherT.cond[F](child.timestamp > parent.timestamp, (), NonEmptyChain("Non-Forward Timestamp"))
      _ <- EitherT.cond[F](child.height === parent.height + 1, (), NonEmptyChain("Non-Forward Height"))
    } yield child

  private[consensus] def timeSlotVerification(header: BlockHeader): ValidationResult[F] =
    EitherT
      .liftF(clock.timestampToSlot(header.timestamp))
      .ensure(NonEmptyChain("TimestampSlotMismatch"))(_ == header.slot) >>
      EitherT
        .liftF(clock.globalSlot)
        .ensure(NonEmptyChain("FutureBlock"))(_ + 10 >= header.slot)
        .void

  /** Verifies the given block's VRF certificate syntactic integrity for a particular stateful nonce
    */
  private[consensus] def vrfVerification(header: BlockHeader): ValidationResult[F] =
    for {
      expectedEta <- EitherT.liftF(
        etaCalculation.etaToBe(
          SlotId(header.parentSlot, header.parentHeaderId),
          header.slot
        )
      )
      eta = header.eligibilityCertificate.eta.decodeBase58
      _ <- EitherT.cond[F](eta == expectedEta, (), NonEmptyChain("Invalid Eta"))
      signatureVerificationResult <- EitherT.liftF(
        CryptoResources[F].ed25519VRF
          .useSync(
            _.verify(
              header.eligibilityCertificate.vrfSig.decodeBase58,
              VrfArgument(
                expectedEta,
                header.slot
              ).signableBytes.toByteArray,
              header.eligibilityCertificate.vrfVK.decodeBase58
            )
          )
      )
      _ <- EitherT.cond[F](signatureVerificationResult, (), NonEmptyChain("InvalidEligibilityProof"))
    } yield ()

  /** Verifies the given block's Operational Certificate's parent -> linear commitment, and the Operational
    * Certificate's block signature
    */
  private[consensus] def kesVerification(
      header: BlockHeader
  ): ValidationResult[F] =
    for {
      message <- EitherT.liftF(
        Sync[F].delay(
          header.operationalCertificate.childVK.decodeBase58.toByteArray ++
            Longs.toByteArray(header.slot)
        )
      )
      parentCommitmentResult <- EitherT.liftF(
        CryptoResources[F].kesProduct
          .useSync(
            _.verify(
              header.operationalCertificate.parentSignature,
              message,
              header.operationalCertificate.parentVK
            )
          )
      )
      _ <- EitherT.cond[F](parentCommitmentResult, (), NonEmptyChain("InvalidOperationalParentSignature"))
      childSignatureResult <- EitherT.liftF(
        CryptoResources[F].ed25519
          .useSync(
            _.verify(
              header.operationalCertificate.childSignature.decodeBase58.toByteArray,
              header.unsigned.signableBytes.toByteArray,
              header.operationalCertificate.childVK.decodeBase58.toByteArray
            )
          )
      )
      _ <- EitherT.cond[F](childSignatureResult, (), NonEmptyChain("InvalidBlockProof"))
    } yield ()

  /** Determines the VRF threshold for the given child
    */
  private def vrfThresholdFor(
      child: BlockHeader,
      parent: BlockHeader
  ): EitherT[F, NonEmptyChain[String], Ratio] =
    EitherT
      .fromOptionF(
        stakerTracker.stakerRelativeStake(parent.id, child.slot, child.account),
        NonEmptyChain("UnregisteredStaker")
      )
      .semiflatMap(leaderElection.getThreshold(_, child.slot - parent.slot))

  /** Verify that the threshold evidence stamped on the block matches the threshold generated using local state
    */
  private[consensus] def vrfThresholdVerification(
      header: BlockHeader,
      threshold: Ratio
  ): ValidationResult[F] =
    for {
      evidence <-
        EitherT
          .liftF[F, NonEmptyChain[String], Bytes](
            CryptoResources[F].blake2b256.useSync(implicit b => thresholdEvidence(threshold))
          )
      _ <-
        EitherT.cond[F](
          header.eligibilityCertificate.thresholdEvidence.decodeBase58 == evidence,
          (),
          NonEmptyChain("InvalidVRFThreshold")
        )
    } yield ()

  /** Verify that the block's staker is eligible using their relative stake distribution
    */
  private[consensus] def eligibilityVerification(
      header: BlockHeader,
      threshold: Ratio
  ): ValidationResult[F] =
    for {
      rho <- EitherT
        .liftF(
          CryptoResources[F].ed25519VRF
            .useSync(
              _.proofToHash(
                header.eligibilityCertificate.vrfSig.decodeBase58
              )
            )
        )
      isEligible <- EitherT.liftF(leaderElection.isEligible(threshold, rho))
      _ <- EitherT.cond[F](isEligible, (), NonEmptyChain("Ineligible"))
    } yield ()

  /** Verifies the staker's registration. First checks that the staker is registered at all. Once retrieved, the
    * registration contains a commitment/proof that must be verified using the 0th timestep of the header's operational
    * certificate's "parentVK". The proof's message is the hash of (the staker's vrfVK concatenated with the staker's
    * poolVK).
    */
  private[consensus] def registrationVerification(
      header: BlockHeader
  ): ValidationResult[F] =
    for {
      staker <-
        EitherT.fromOptionF(
          stakerTracker.staker(header.parentHeaderId, header.slot, header.account),
          NonEmptyChain("Unregistered")
        )
      message <- EitherT.liftF(
        CryptoResources[F].blake2b256
          .useSync(
            _.hash(
              header.eligibilityCertificate.vrfVK.decodeBase58,
              staker.registration.stakingAddress.value.decodeBase58
            )
          )
      )
      isValid <- EitherT.liftF(
        CryptoResources[F].kesProduct
          .useSync(
            _.verify(
              staker.registration.signature,
              message,
              header.operationalCertificate.parentVK.copy(step = 0)
            )
          )
      )
      _ <- EitherT
        .cond[F](
          isValid,
          (),
          NonEmptyChain("Registration-Commitment Mismatch")
        )
    } yield ()
