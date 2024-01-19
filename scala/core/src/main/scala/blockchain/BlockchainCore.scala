package blockchain

import blockchain.consensus.*
import blockchain.crypto.CryptoResources
import blockchain.codecs.given
import blockchain.ledger.Ledger
import blockchain.models.*
import cats.effect.Async
import cats.implicits.*
import cats.effect.implicits.*
import fs2.{Chunk, Pipe, Pull, Stream}

import java.time.Instant

case class BlockchainCore[F[_]](
    clock: Clock[F],
    dataStores: DataStores[F],
    cryptoResources: CryptoResources[F],
    blockIdTree: BlockIdTree[F],
    consensus: Consensus[F],
    ledger: Ledger[F]
):

  def traversalBetween(a: BlockId, b: BlockId): Stream[F, TraversalStep] =
    Stream
      .eval(blockIdTree.findCommonAncestor(a, b))
      .flatMap(ancestorTrace =>
        Stream
          .foldable(ancestorTrace._1.tail)
          .map(TraversalStep.Unapplied(_)) ++
          Stream.foldable(ancestorTrace._2.tail).map(TraversalStep.Applied(_))
      )

  def traversal: Stream[F, TraversalStep] = {
    def pullSteps(currentHead: BlockId): Pipe[F, BlockId, TraversalStep] = {
      def go(
          s: Stream[F, BlockId],
          currentHead: BlockId
      ): Pull[F, TraversalStep, Unit] =
        s.pull.uncons1.flatMap {
          case Some((head, tlStream)) =>
            Pull
              .eval(blockIdTree.findCommonAncestor(currentHead, head))
              .map { case (unapplyChain, applyChain) =>
                unapplyChain.tail.map(TraversalStep.Unapplied(_)) ++
                  applyChain.tail.map(TraversalStep.Applied(_))
              }
              .map(Chunk.chain)
              .flatMap(steps => Pull.output(steps) >> go(tlStream, head))
          case None =>
            Pull.done
        }

      in => go(in, currentHead).stream
    }
    Stream
      .eval(consensus.localChain.currentHead)
      .flatMap(currentHead =>
        consensus.localChain.adoptions.through(pullSteps(currentHead))
      )
  }

object BlockchainCore:
  def make[F[_]: Async] =
    for {
      // TODO
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
    } yield BlockchainCore(
      clock,
      dataStores,
      cryptoResources,
      blockIdTree,
      consensus,
      ledger
    )
