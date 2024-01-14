package blockchain.consensus

import blockchain.*
import blockchain.codecs.given
import blockchain.crypto.CryptoResources
import blockchain.models.*
import blockchain.utility.{Exp, Log1P}
import cats.effect.{Async, Resource}
import cats.implicits.*
import cats.effect.implicits.*

case class Consensus[F[_]](
    headerValidation: HeaderValidation[F],
    chainSelection: ChainSelection[F],
    stakerTracker: StakerTracker[F],
    etaCalculation: EtaCalculation[F],
    leaderElection: LeaderElection[F],
    localChain: LocalChain[F]
)

object Consensus:
  def make[F[_]: Async](
      genesis: FullBlock,
      clock: Clock[F],
      dataStores: DataStores[F],
      cryptoResources: CryptoResources[F],
      eventIdGetterSetters: EventIdGetterSetters[F],
      blockIdTree: BlockIdTree[F],
      blockHeights: BlockHeights.BSS[F]
  ): Resource[F, Consensus[F]] =
    for {
      protocolSettings <- Resource.pure[F, ProtocolSettings](
        ProtocolSettings.Default.merge(genesis.header.settings)
      )
      etaCalculation <- EtaCalculation.make[F](
        dataStores.headers.getOrRaise,
        clock,
        genesis.header.eligibilityCertificate.eta,
        cryptoResources.blake2b256,
        cryptoResources.blake2b512,
        cryptoResources.ed25519VRF
      )
      epochBoundariesBSS <- EpochBoundaries.make[F](
        dataStores.epochBoundaries.pure[F],
        eventIdGetterSetters.epochBoundaries.get(),
        blockIdTree,
        eventIdGetterSetters.epochBoundaries.set,
        clock,
        dataStores.headers.getOrRaise
      )
      stakerDataBSS <- StakerData.make[F](
        StakerData
          .State(
            dataStores.activeStake,
            dataStores.inactiveStake,
            dataStores.stakers
          )
          .pure[F],
        eventIdGetterSetters.stakerData.get(),
        blockIdTree,
        eventIdGetterSetters.stakerData.set,
        dataStores.bodies.getOrRaise,
        dataStores.transactions.getOrRaise
      )
      stakerTracker <- StakerTracker
        .make[F](clock, genesis.header.id, stakerDataBSS, epochBoundariesBSS)
      canonicalHeadId <- eventIdGetterSetters.canonicalHead.get().toResource
      localChain <- LocalChain
        .make[F](genesis.header.id, blockHeights, canonicalHeadId)
      chainSelection <- ChainSelection.make[F](
        cryptoResources.blake2b512,
        cryptoResources.ed25519VRF,
        protocolSettings.chainSelectionKLookback,
        protocolSettings.chainSelectionSWindow
      )
      exp <- Exp.make()
      log1p <- Log1P.make() >>= Log1P.makeCached
      leaderElection <- LeaderElection.make(
        protocolSettings,
        cryptoResources.blake2b512,
        exp,
        log1p
      )
      headerValidation <- HeaderValidation.make[F](
        genesis.header.id,
        etaCalculation,
        stakerTracker,
        leaderElection,
        clock,
        dataStores.headers.getOrRaise,
        cryptoResources
      )
    } yield Consensus(
      headerValidation,
      chainSelection,
      stakerTracker,
      etaCalculation,
      leaderElection,
      localChain
    )
