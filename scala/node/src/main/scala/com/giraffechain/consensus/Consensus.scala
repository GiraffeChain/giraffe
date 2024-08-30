package com.giraffechain.consensus

import com.giraffechain.*
import com.giraffechain.codecs.{*, given}
import com.giraffechain.crypto.CryptoResources
import com.giraffechain.models.*
import com.giraffechain.utility.{Exp, Log1P}
import cats.effect.{Async, Resource}
import cats.implicits.*
import cats.effect.implicits.*
import org.typelevel.log4cats.slf4j.Slf4jLogger

case class Consensus[F[_]](
    headerValidation: HeaderValidation[F],
    chainSelection: ChainSelection[F],
    stakerTracker: StakerTracker[F],
    etaCalculation: EtaCalculation[F],
    leaderElection: LeaderElection[F],
    localChain: LocalChain[F]
)

object Consensus:
  def make[F[_]: Async: CryptoResources](
      genesis: FullBlock,
      clock: Clock[F],
      dataStores: DataStores[F],
      eventIdGetterSetters: EventIdGetterSetters[F],
      blockIdTree: BlockIdTree[F],
      blockHeights: BlockHeights.BSS[F]
  ): Resource[F, Consensus[F]] =
    for {
      logger <- Slf4jLogger.fromName("Consensus").toResource
      protocolSettings <- Resource.pure[F, ProtocolSettings](ProtocolSettings.Default.merge(genesis.header.settings))
      etaCalculation <- EtaCalculation
        .make[F](dataStores.headers.getOrRaise, clock, genesis.header.stakerCertificate.eta.decodeBase58)
      epochBoundariesBSS <- EpochBoundaries.make[F](
        dataStores.epochBoundaries.pure[F],
        eventIdGetterSetters.epochBoundaries.get(),
        blockIdTree,
        eventIdGetterSetters.epochBoundaries.set,
        clock,
        dataStores.headers.getOrRaise
      )
      stakerDataBSS <- StakerData.make[F](
        StakerData.State(dataStores.activeStake, dataStores.inactiveStake, dataStores.stakers).pure[F],
        eventIdGetterSetters.stakerData.get(),
        blockIdTree,
        eventIdGetterSetters.stakerData.set,
        dataStores.bodies.getOrRaise,
        dataStores.transactions.getOrRaise
      )
      stakerTracker <- StakerTracker.make[F](clock, genesis.header.id, stakerDataBSS, epochBoundariesBSS)
      canonicalHeadId <- eventIdGetterSetters.canonicalHead.get().toResource
      canonicalHead <- dataStores.headers.getOrRaise(canonicalHeadId).toResource
      _ <- logger
        .info(
          show"Canonical head id=$canonicalHeadId height=${canonicalHead.height} slot=${canonicalHead.slot}"
        )
        .toResource
      localChain <- LocalChain.make[F](genesis.header.id, blockHeights, canonicalHeadId, dataStores.headers.getOrRaise)
      _ <- localChain.adoptions.evalTap(eventIdGetterSetters.canonicalHead.set).compile.drain.background
      chainSelection <- ChainSelection.make[F](
        CryptoResources[F].blake2b512,
        CryptoResources[F].ed25519VRF,
        protocolSettings.chainSelectionKLookback,
        protocolSettings.chainSelectionSWindow
      )
      exp <- Exp.make()
      log1p <- Log1P.make() >>= Log1P.makeCached
      leaderElection <- LeaderElection.make(
        protocolSettings,
        CryptoResources[F].blake2b512,
        exp,
        log1p
      )
      headerValidation <- HeaderValidation.make[F](
        genesis.header.id,
        etaCalculation,
        stakerTracker,
        leaderElection,
        clock,
        dataStores.headers.getOrRaise
      )
    } yield Consensus(
      headerValidation,
      chainSelection,
      stakerTracker,
      etaCalculation,
      leaderElection,
      localChain
    )
