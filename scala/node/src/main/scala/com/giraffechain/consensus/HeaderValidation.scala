package com.giraffechain.consensus

import cats.data.{EitherT, NonEmptyChain}
import cats.effect.{Resource, Async}
import cats.implicits.*
import com.giraffechain.codecs.{*, given}
import com.giraffechain.crypto.CryptoResources
import com.giraffechain.models.{ActiveStaker, BlockHeader, BlockId, SlotId}
import com.giraffechain.utility.*
import com.giraffechain.{*, given}

trait HeaderValidation[F[_]]:
  def validate(blockHeader: BlockHeader): ValidationResult[F]

object HeaderValidation:
  def make[F[_]: Async: CryptoResources](
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

class HeaderValidationImpl[F[_]: Async: CryptoResources](
    genesisId: BlockId,
    etaCalculation: EtaCalculation[F],
    stakerTracker: StakerTracker[F],
    leaderElection: LeaderElection[F],
    clock: Clock[F],
    fetchHeader: BlockId => F[BlockHeader]
) extends HeaderValidation[F]:
  override def validate(header: BlockHeader): ValidationResult[F] =
    if (header.id == genesisId) EitherT.pure(())
    else {
      List(
        timeSlotVerification(header),
        (EitherT.liftF(fetchHeader(header.parentHeaderId)), registrationVerification(header)).parTupled.flatMap(
          (parent, staker) =>
            vrfVerification(header, parent) &>
              statelessVerification(header, parent) &>
              blockSignatureVerification(header)(staker) &>
              vrfThresholdFor(header, parent).flatMap(eligibilityVerification(header, _))
        )
      ).parSequence.map(_.void)
    }

  private[consensus] def statelessVerification(child: BlockHeader, parent: BlockHeader): ValidationResult[F] =
    for {
      _ <- EitherT.cond[F](child.slot > parent.slot, (), NonEmptyChain("Non-Forward Slot"))
      _ <- EitherT.cond[F](child.timestamp > parent.timestamp, (), NonEmptyChain("Non-Forward Timestamp"))
      _ <- EitherT.cond[F](child.height === parent.height + 1, (), NonEmptyChain("Non-Forward Height"))
    } yield ()

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
  private[consensus] def vrfVerification(child: BlockHeader, parent: BlockHeader): ValidationResult[F] =
    for {
      expectedEta <- EitherT.liftF(
        etaCalculation.etaToBe(
          SlotId(parent.slot, child.parentHeaderId),
          child.slot
        )
      )
      eta = child.stakerCertificate.eta.decodeBase58
      _ <- EitherT.cond[F](eta == expectedEta, (), NonEmptyChain("Invalid Eta"))
      signatureVerificationResult <- EitherT.liftF(
        CryptoResources[F].ed25519VRF
          .useSync(
            _.verify(
              child.stakerCertificate.vrfSignature.decodeBase58,
              VrfArgument(
                expectedEta,
                child.slot
              ).signableBytes.toByteArray,
              child.stakerCertificate.vrfVK.decodeBase58
            )
          )
      )
      _ <- EitherT.cond[F](signatureVerificationResult, (), NonEmptyChain("InvalidEligibilityProof"))
    } yield ()

  /** Verifies the given block's signature is verified by the staker's registered VK
    */
  private[consensus] def blockSignatureVerification(
      header: BlockHeader
  )(staker: ActiveStaker): ValidationResult[F] =
    for {
      childSignatureResult <- EitherT.liftF(
        CryptoResources[F].ed25519
          .useSync(
            _.verify(
              header.stakerCertificate.blockSignature.decodeBase58.toByteArray,
              header.unsigned.signableBytes.toByteArray,
              staker.registration.vk.decodeBase58.toByteArray
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
                header.stakerCertificate.vrfSignature.decodeBase58
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
  ): EitherT[F, NonEmptyChain[String], ActiveStaker] =
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
              header.stakerCertificate.vrfVK.decodeBase58
            )
          )
      )
      isValid <- EitherT.liftF(
        CryptoResources[F].ed25519
          .useSync(
            _.verify(
              staker.registration.commitmentSignature.decodeBase58,
              message,
              staker.registration.vk.decodeBase58
            )
          )
      )
      _ <- EitherT.cond[F](isValid, (), NonEmptyChain("Registration-Commitment Mismatch"))
    } yield staker
