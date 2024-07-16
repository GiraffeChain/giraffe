package blockchain.consensus

import blockchain.*
import blockchain.codecs.{*, given}
import blockchain.crypto.*
import blockchain.models.{BlockHeader, BlockId, SlotId}
import blockchain.utility.*
import cats.*
import cats.data.*
import cats.effect.{Clock as _, *}
import cats.implicits.*
import com.github.benmanes.caffeine.cache.Caffeine
import com.google.protobuf.ByteString
import org.typelevel.log4cats.Logger
import org.typelevel.log4cats.slf4j.Slf4jLogger
import scalacache.caffeine.CaffeineCache
import scalacache.{Cache, Entry}

trait EtaCalculation[F[_]]:
  def etaToBe(parentSlotId: SlotId, childSlot: Long): F[Eta]

object EtaCalculation:
  def make[F[_]: Async: Parallel: CryptoResources](
      fetchHeader: BlockId => F[BlockHeader],
      clock: Clock[F],
      genesisEta: Eta
  ): Resource[F, EtaCalculation[F]] =
    Resource.pure(
      new EtaCalculationImpl[F](
        fetchHeader,
        clock,
        genesisEta,
        CaffeineCache[F, BlockId, Eta](
          Caffeine.newBuilder.maximumSize(32).build[BlockId, Entry[Eta]]()
        )
      )
    )

private[consensus] class EtaCalculationImpl[F[_]: Async: Parallel: CryptoResources](
    fetchHeader: BlockId => F[BlockHeader],
    clock: Clock[F],
    genesisEta: Eta,
    cache: Cache[F, BlockId, Eta]
) extends EtaCalculation[F] {

  implicit private val logger: Logger[F] =
    Slf4jLogger.getLoggerFromName("Blockchain.Consensus.EtaCalculation")

  private val twoThirdsLength = clock.epochLength * 2 / 3

  override def etaToBe(parentSlotId: SlotId, childSlot: Long): F[Eta] =
    clock
      .epochOf(childSlot)
      .flatMap(childEpoch =>
        if (childEpoch === 0L) genesisEta.pure[F]
        else
          for {
            parentEpoch <- clock.epochOf(parentSlotId.slot)
            parentSlotData <- fetchHeader(parentSlotId.blockId)
            eta <-
              if (parentEpoch === childEpoch)
                Async[F].delay(parentSlotData.eligibilityCertificate.eta.decodeBase58)
              else if (childEpoch - parentEpoch > 1)
                MonadThrow[F].raiseError(
                  new IllegalStateException(
                    show"Eta calculation encountered empty epoch for" +
                      show" parentSlotId=$parentSlotId" +
                      show" childSlot=$childSlot" +
                      show" parentEpoch=$parentEpoch" +
                      show" childEpoch=$childEpoch"
                  )
                )
              else locateTwoThirdsBest(parentSlotData).flatMap(calculate)
          } yield eta
      )

  /** Given some header near the end of an epoch, traverse the chain (toward genesis) until reaching a block that is
    * inside of the 2/3 window of the epoch
    */
  private def locateTwoThirdsBest(from: BlockHeader): F[BlockHeader] =
    if (isWithinTwoThirds(from)) from.pure[F]
    else
      from.iterateUntilM(data => fetchHeader(data.parentHeaderId))(
        isWithinTwoThirds
      )

  private def isWithinTwoThirds(from: BlockHeader): Boolean =
    from.slot % clock.epochLength <= twoThirdsLength

  /** Compute the Eta value for the epoch containing the given header
    * @param twoThirdsBest
    *   The latest block header in some tine, but within the first 2/3 of the epoch
    */
  private def calculate(twoThirdsBest: BlockHeader): F[Eta] =
    cache.cachingF(twoThirdsBest.id)(ttl = None)(
      Sync[F].defer(
        for {
          epoch <- clock.epochOf(twoThirdsBest.slot)
          epochRange <- clock.epochRange(epoch)
          epochData <- NonEmptyChain(twoThirdsBest).iterateUntilM(items =>
            fetchHeader(items.head.parentHeaderId).map(items.prepend)
          )(items => items.head.parentSlot < epochRange.start)
          rhoValues <- epochData.parTraverse(header => CryptoResources[F].ed25519VRF.useSync(e => header.rho(using e)))
          nextEta <- calculate(
            previousEta = twoThirdsBest.eligibilityCertificate.eta.decodeBase58,
            epoch = epoch + 1,
            rhoValues = rhoValues
          )
        } yield nextEta
      )
    )

  /** Calculate a new Eta value once all the necessary pre-requisites have been gathered
    */
  private def calculate(
      previousEta: Eta,
      epoch: Long,
      rhoValues: NonEmptyChain[Rho]
  ): F[Eta] =
    for {
      _ <- Logger[F].debug(
        show"Calculating new eta." +
          show" previousEta=$previousEta" +
          show" epoch=$epoch" +
          show" rhoValues=[${rhoValues.length}]{${rhoValues.head}..${rhoValues.last}}"
      )
      rhoNonceHashes <- rhoValues
        .parTraverse(rho =>
          CryptoResources[F].blake2b512
            .useSync(implicit b2b => rhoToRhoNonceHash(rho))
        )
      nextEta <- calculateFromNonceHashValues(
        previousEta,
        epoch,
        rhoNonceHashes
      )
      _ <- Logger[F].info(
        show"Calculated new eta." +
          show" previousEta=$previousEta" +
          show" epoch=$epoch" +
          show" rhoValues=[${rhoValues.length}]{${rhoValues.head}..${rhoValues.last}}" +
          show" nextEta=$nextEta"
      )
    } yield nextEta

  /** Calculate a new Eta value once all the necessary pre-requisites have been gathered
    */
  private def calculateFromNonceHashValues(
      previousEta: Eta,
      epoch: Long,
      rhoNonceHashValues: NonEmptyChain[RhoHash]
  ): F[Eta] =
    Sync[F]
      .delay(
        EtaCalculationArgs(
          previousEta,
          epoch,
          rhoNonceHashValues.toIterable
        ).digestMessages
      )
      .map(_.map(_.toByteArray))
      .flatMap(bytes => CryptoResources[F].blake2b256.useSync(_.hash(bytes*)))
      .map(ByteString.copyFrom)

}
case class EtaCalculationArgs(
    previousEta: Eta,
    epoch: Epoch,
    rhoNonceHashValues: Iterable[RhoHash]
) {

  def digestMessages: List[Bytes] =
    previousEta +:
      epoch.immutableBytes +:
      rhoNonceHashValues.toList
}
