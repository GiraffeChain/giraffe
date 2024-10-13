package com.giraffechain.consensus

import cats.data.OptionT
import cats.effect.{Resource, Sync}
import cats.implicits.*
import com.giraffechain.*
import com.giraffechain.codecs.given
import com.giraffechain.crypto.{Blake2b512, Ed25519VRF}
import com.giraffechain.models.*
import org.typelevel.log4cats.Logger
import org.typelevel.log4cats.slf4j.*

trait ChainSelection[F[_]]:
  def compare(
      headerX: BlockHeader,
      headerY: BlockHeader,
      commonAncestor: BlockHeader,
      headerAtHeightA: Height => F[Option[BlockHeader]],
      headerAtHeightB: Height => F[Option[BlockHeader]]
  ): F[ChainSelectionOutcome]

object ChainSelection:
  def make[F[_]: Sync](
      blake2b512Resource: Resource[F, Blake2b512],
      ed25519VRFResource: Resource[F, Ed25519VRF],
      kLookback: Long,
      sWindow: Long
  ): Resource[F, ChainSelection[F]] =
    Resource.pure(
      new ChainSelectionImpl[F](
        blake2b512Resource,
        ed25519VRFResource,
        kLookback,
        sWindow
      )
    )

sealed trait ChainSelectionOutcome:
  def isX: Boolean
  def isY: Boolean

object ChainSelectionOutcome:
  sealed trait XChainSelectionOutcome:
    self: ChainSelectionOutcome =>
    def isX = true
    def isY = false

  sealed trait YChainSelectionOutcome:
    self: ChainSelectionOutcome =>
    def isX = false
    def isY = true

  case object XStandard extends ChainSelectionOutcome with XChainSelectionOutcome

  case object YStandard extends ChainSelectionOutcome with YChainSelectionOutcome

  case object XDensity extends ChainSelectionOutcome with XChainSelectionOutcome

  case object YDensity extends ChainSelectionOutcome with YChainSelectionOutcome

class ChainSelectionImpl[F[_]: Sync](
    blake2b512Resource: Resource[F, Blake2b512],
    ed25519VRFResource: Resource[F, Ed25519VRF],
    kLookback: Long,
    sWindow: Long
) extends ChainSelection[F]:

  given Logger[F] =
    Slf4jLogger.getLoggerFromName("Blockchain.ChainSelection")

  def compare(
      xHead: BlockHeader,
      yHead: BlockHeader,
      commonAncestor: BlockHeader,
      fetchXAtHeight: Height => F[Option[BlockHeader]],
      fetchYAtHeight: Height => F[Option[BlockHeader]]
  ): F[ChainSelectionOutcome] = (
    if (yHead.id == commonAncestor.id)
      Sync[F].pure[ChainSelectionOutcome](ChainSelectionOutcome.XStandard)
    else if (xHead.id == commonAncestor.id)
      Sync[F].pure[ChainSelectionOutcome](ChainSelectionOutcome.YStandard)
    else if (xHead.height - commonAncestor.height <= kLookback && yHead.height - commonAncestor.height <= kLookback)
      standardOrderOutcome(xHead, yHead)
    else
      Logger[F].info("Starting density chain selection process") >>
        densityBoundaryBlock(commonAncestor, fetchXAtHeight).flatMap(xBoundary =>
          OptionT(fetchYAtHeight(xBoundary.height))
            .filterNot(_.slot - commonAncestor.slot > sWindow)
            .foldF[ChainSelectionOutcome](
              ChainSelectionOutcome.XDensity.pure[F].widen
            )(yAtX =>
              OptionT(fetchYAtHeight(xBoundary.height + 1))
                .filterNot(_.slot - commonAncestor.slot > sWindow)
                .as(ChainSelectionOutcome.YDensity)
                .getOrElseF(
                  // Tie Breaker
                  standardOrderOutcome(xBoundary, yAtX)
                    .map(outcome =>
                      if (outcome.isX) ChainSelectionOutcome.XDensity
                      else ChainSelectionOutcome.YDensity
                    )
                )
            )
        )
  )
    .flatTap(logOutcome(xHead, yHead))

  private def standardOrderOutcome(
      x: BlockHeader,
      y: BlockHeader
  ): F[ChainSelectionOutcome] =
    if (x.height > y.height) ChainSelectionOutcome.XStandard.pure[F]
    else if (x.height < y.height) ChainSelectionOutcome.YStandard.pure[F]
    else if (x.slot > y.slot) ChainSelectionOutcome.YStandard.pure[F]
    else if (x.slot < y.slot) ChainSelectionOutcome.XStandard.pure[F]
    else
      (
        headerToRhoTestHashBigInt(x),
        headerToRhoTestHashBigInt(y)
      ).mapN((xRTH, yRTH) =>
        if (BigInt(yRTH.toByteArray) > BigInt(xRTH.toByteArray))
          ChainSelectionOutcome.YStandard
        else ChainSelectionOutcome.XStandard
      )

  private def headerToRhoTestHashBigInt(header: BlockHeader) =
    ed25519VRFResource
      .use(implicit e => Sync[F].delay(header.rho))
      .flatMap(rho => blake2b512Resource.use(implicit b => Sync[F].delay(rhoToRhoTestHash(rho))))

  /** Starting from the given common ancestor, traverses forward along the chain, keeping all blocks that fall within
    * the protocol's `sWindow` setting.
    *
    * TODO: Optimization: Use (fEffective * sWindow) + commonAncestor.height to guide the search process
    *
    * @param commonAncestor
    *   The starting point for the search
    * @param fetchHeader
    *   A lookup function to find a block-by-height
    * @return
    *   The "best" BlockHeader that comes after the common ancestor but within the protocol's sWindow
    */
  private def densityBoundaryBlock(
      commonAncestor: BlockHeader,
      fetchHeader: Long => F[Option[BlockHeader]]
  ): F[BlockHeader] =
    commonAncestor.tailRecM(currentBoundary =>
      OptionT(fetchHeader(currentBoundary.height + 1))
        .filterNot(_.slot - commonAncestor.slot > sWindow)
        .toLeft(currentBoundary)
        .value
    )

  private def logOutcome(xHead: BlockHeader, yHead: BlockHeader)(
      outcome: ChainSelectionOutcome
  ): F[Unit] =
    outcome match {
      case ChainSelectionOutcome.XStandard =>
        Logger[F].info(
          show"X(id=${xHead.id}) is better than Y(id=${yHead.id}) using algorithm=standard"
        )
      case ChainSelectionOutcome.YStandard =>
        Logger[F].info(
          show"Y(id=${yHead.id}) is better than X(id=${xHead.id}) using algorithm=standard"
        )
      case ChainSelectionOutcome.XDensity =>
        Logger[F].info(
          show"X(id=${xHead.id}) is better than Y(id=${yHead.id}) using algorithm=density"
        )
      case ChainSelectionOutcome.YDensity =>
        Logger[F].info(
          show"Y(id=${yHead.id}) is better than X(id=${xHead.id}) using algorithm=density"
        )
    }
