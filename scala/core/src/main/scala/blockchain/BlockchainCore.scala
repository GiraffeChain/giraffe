package blockchain

import blockchain.consensus.{BlockHeights, Consensus, ProtocolSettings}
import blockchain.crypto.CryptoResources
import blockchain.codecs.given
import blockchain.ledger.Ledger
import blockchain.models.*
import cats.effect.Async
import cats.implicits.*
import cats.effect.implicits.*

import java.time.Instant

case class BlockchainCore[F[_]](
    clock: Clock[F],
    dataStores: DataStores[F],
    blockIdTree: BlockIdTree[F],
    consensus: Consensus[F],
    ledger: Ledger[F]
)

object BlockchainCore:
  def make[F[_]: Async] =
    for {
      genesis <- (null: FullBlock).pure[F].toResource
      clock <- Clock.make(
        ProtocolSettings.Default,
        Instant.ofEpochMilli(genesis.header.timestamp)
      )
      cryptoResources <- CryptoResources.make[F]
      dataStores <- DataStores.make(???) // TODO init
      blockIdTree <- BlockIdTree.make(
        dataStores.blockIdTree.get,
        dataStores.blockIdTree.put,
        genesis.header.parentHeaderId
      )
      eventIdGetterSetters = new EventIdGetterSetters[F](
        dataStores.currentEventIds
      )
      blockHeights <- BlockHeights.make(
        dataStores.blockHeightIndex,
        eventIdGetterSetters.blockHeightTree.get(),
        blockIdTree,
        eventIdGetterSetters.blockHeightTree.set,
        dataStores.headers.getOrRaise
      )
      consensus <- Consensus.make(
        genesis,
        clock,
        dataStores,
        cryptoResources,
        eventIdGetterSetters,
        blockIdTree,
        blockHeights
      )
      ledger <- Ledger.make(
        dataStores,
        eventIdGetterSetters,
        blockIdTree,
        clock,
        consensus.localChain
      )
    } yield BlockchainCore(clock, dataStores, blockIdTree, consensus, ledger)
