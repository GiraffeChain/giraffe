package blockchain.consensus

import blockchain.Slot
import blockchain.crypto.Blake2b512
import blockchain.utility.{Exp, Log1P, Ratio}
import cats.implicits.*
import cats.effect.{Resource, Sync}
import com.github.benmanes.caffeine.cache.Caffeine
import scalacache.Entry
import scalacache.caffeine.CaffeineCache

trait LeaderElection[F[_]]:
  def getThreshold(relativeStake: Ratio, slotDiff: Long): F[Ratio]
  def isEligible(threshold: Ratio, rho: Rho): F[Boolean]

object LeaderElection:
  def make[F[_]: Sync](
      protocolSettings: ProtocolSettings,
      blake2b512Resource: Resource[F, Blake2b512],
      exp: Exp[F],
      log1p: Log1P[F]
  ): Resource[F, LeaderElection[F]] =
    Resource
      .pure(
        CaffeineCache[F, (Ratio, Slot), Ratio](
          Caffeine.newBuilder
            .maximumSize(32)
            .build[(Ratio, Slot), Entry[Ratio]]()
        )
      )
      .map(
        new LeaderElectionImpl[F](
          protocolSettings,
          blake2b512Resource,
          exp,
          log1p,
          _
        )
      )

class LeaderElectionImpl[F[_]: Sync](
    protocolSettings: ProtocolSettings,
    blake2b512Resource: Resource[F, Blake2b512],
    exp: Exp[F],
    log1p: Log1P[F],
    cache: CaffeineCache[F, (Ratio, Slot), Ratio]
) extends LeaderElection[F]:
  override def getThreshold(
      relativeStake: Ratio,
      uncappedSlotDiff: Long
  ): F[Ratio] = {
    val slotDiff = uncappedSlotDiff.min(protocolSettings.vrfLddCutoff + 1)
    cache.cachingF((relativeStake, slotDiff))(ttl = None)(
      Sync[F]
        .delay(
          if (slotDiff > protocolSettings.vrfLddCutoff)
            protocolSettings.vrfBaselineDifficulty
          else
            Ratio(
              BigInt(slotDiff),
              BigInt(protocolSettings.vrfLddCutoff)
            ) * protocolSettings.vrfAmplitude
        )
        .flatMap(difficultyCurve =>
          if (difficultyCurve == Ratio.One) {
            Ratio.One.pure[F]
          } else
            for {
              coefficient <- log1p.evaluate(Ratio.NegativeOne * difficultyCurve)
              result <- exp.evaluate(coefficient * relativeStake)
            } yield Ratio.One - result
        )
    )
  }

  override def isEligible(threshold: Ratio, rho: Rho): F[Boolean] =
    blake2b512Resource
      .use(implicit blake2b512 => Sync[F].delay(rhoToRhoTestHash(rho).toByteArray))
      .map { testRhoHashBytes =>
        val test = Ratio(
          BigInt(Array(0x00.toByte) ++ testRhoHashBytes),
          LeaderElectionImpl.NormalizationConstant,
          BigInt(1)
        )
        threshold > test
      }

object LeaderElectionImpl:
  /** Normalization constant for test nonce hash evaluation based on 512 byte hash function output
    */
  private val NormalizationConstant: BigInt = BigInt(2).pow(512)
