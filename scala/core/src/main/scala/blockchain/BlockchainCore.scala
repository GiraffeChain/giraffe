package blockchain

import blockchain.codecs.{given}
import blockchain.consensus.*
import blockchain.crypto.CryptoResources
import blockchain.ledger.Ledger
import blockchain.models.*
import cats.effect.implicits.*
import cats.effect.{Async, Resource}
import cats.implicits.*
import fs2.io.file.{Files, Path}
import fs2.{Chunk, Pipe, Pull, Stream}
import org.typelevel.log4cats.slf4j.Slf4jLogger

import java.time.Instant

case class BlockchainCore[F[_]](
    protocolSettings: ProtocolSettings,
    clock: Clock[F],
    dataStores: DataStores[F],
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
      .flatMap(currentHead => consensus.localChain.adoptions.through(pullSteps(currentHead)))
  }

object BlockchainCore:
  def make[F[_]: Async: Files: CryptoResources](genesis: FullBlock, dataDir: Path): Resource[F, BlockchainCore[F]] =
    for {
      logger <- Slf4jLogger.fromName("Blockchain").toResource
      protocolSettings = ProtocolSettings.Default.merge(genesis.header.settings)
      _ <- logger.info(protocolSettings.show).toResource
      clock <- Clock.make(protocolSettings, Instant.ofEpochMilli(genesis.header.timestamp))
      globalSlot <- clock.globalSlot.toResource
      globalTimestamp <- clock.globalTimestamp.toResource
      _ <- logger.info(show"Global slot=$globalSlot timestamp=$globalTimestamp").toResource
      dataStores <- DataStores.make(dataDir)
      _ <- dataStores.isInitialized.ifM(().pure[F], dataStores.init(genesis)).toResource
      blockIdTree <- BlockIdTree.make(
        dataStores.blockIdTree.get,
        dataStores.blockIdTree.put,
        genesis.header.parentHeaderId
      )
      eventIdGetterSetters = new EventIdGetterSetters[F](dataStores.currentEventIds)
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
      protocolSettings,
      clock,
      dataStores,
      blockIdTree,
      consensus,
      ledger
    )
