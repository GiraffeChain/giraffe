package com.giraffechain.p2p

import cats.data.OptionT
import cats.effect.Async
import cats.effect.implicits.*
import cats.effect.std.Random
import cats.implicits.*
import com.giraffechain.*
import com.giraffechain.codecs.{*, given}
import com.giraffechain.consensus.ChainSelectionOutcome
import com.giraffechain.ledger.*
import com.giraffechain.models.*
import com.google.protobuf.ByteString
import fs2.{Pipe, Pull, Stream}
import org.typelevel.log4cats.Logger

import scala.concurrent.duration.*

class PeerBlockchainHandler[F[_]: Async: Logger: Random](
    core: BlockchainCore[F],
    interface: PeerBlockchainInterface[F],
    remotePeerState: PeerState[F]
):
  def handle: Stream[F, Unit] =
    pingPong.merge(peerState).mergeHaltR(Stream.exec(start))

  private def pingPong =
    Stream
      .fixedRate(5.seconds)
      .evalMap(_ => Random[F].nextBytes(1024).map(ByteString.copyFrom))
      .evalMap(interface.ping)
      .void

  private def peerState =
    Stream
      .fixedRate(30.seconds)
      .evalMap(_ => interface.publicState)
      .evalMap(remotePeerState.publicStateRef.set)
      .void

  private def start = verifyGenesisAgreement >> syncCheckForever

  private def verifyGenesisAgreement: F[Unit] =
    for {
      remoteGenesisId <- OptionT(interface.blockIdAtHeight(Genesis.Height))
        .getOrRaise(new IllegalArgumentException("No Genesis"))
      localGenesisId <- core.consensus.localChain.genesis
      _ <- Async[F].raiseWhen(remoteGenesisId != localGenesisId)(new IllegalArgumentException("Genesis Mismatch"))
    } yield ()

  private def syncCheckForever: F[Unit] =
    syncCheck.foreverM

  private def syncCheck: F[Unit] =
    for {
      commonAncestorId <- interface.commonAncestor
      remoteHeadId <- OptionT(interface.blockIdAtHeight(0))
        .getOrRaise(new IllegalArgumentException("No Canonical Head"))
      remoteHeader <- OptionT(interface.fetchHeader(remoteHeadId))
        .getOrRaise(new IllegalArgumentException("No Canonical Head"))
      remoteHeaderAtHeightF = (height: Height) =>
        OptionT(interface.blockIdAtHeight(height)).flatMapF(interface.fetchHeader).value
      commonAncestorHeader <- core.dataStores.headers.getOrRaise(commonAncestorId)
      localHeadId <- core.consensus.localChain.currentHead
      localHeader <- core.dataStores.headers.getOrRaise(localHeadId)
      localHeaderAtHeightF = (height: Height) =>
        OptionT(core.consensus.localChain.blockIdAtHeight(height)).flatMapF(core.dataStores.headers.get).value
      chainSelectionResult <- core.consensus.chainSelection.compare(
        localHeader,
        remoteHeader,
        commonAncestorHeader,
        localHeaderAtHeightF,
        remoteHeaderAtHeightF
      )
      _ <- chainSelectionResult match {
        case ChainSelectionOutcome.XStandard =>
          Logger[F].info("Remote peer is up-to-date but local chain is better")
        case ChainSelectionOutcome.YStandard =>
          Logger[F].info("Local peer is up-to-date but remote chain is better")
        case ChainSelectionOutcome.XDensity =>
          Logger[F].info("Remote peer is out-of-sync but local chain is better")
        case ChainSelectionOutcome.YDensity =>
          Logger[F].info("Local peer out-of-sync and remote chain is better")
      }
      _ <- if (chainSelectionResult.isX) inSync else sync(commonAncestorHeader)
    } yield ()

  private def inSync: F[Unit] =
    awaitBetterBlock.race(mempoolSync).void

  private def awaitBetterBlock: F[Unit] =
    interface.nextBlockAdoption
      .flatMap(blockId =>
        Logger[F].info(show"Received block notification id=$blockId") >>
          core.dataStores.headers
            .contains(blockId)
            .ifM(
              Logger[F].info(show"Ignoring known block id=$blockId").as(true),
              OptionT(interface.fetchHeader(blockId))
                .getOrRaise(new IllegalArgumentException("Remote header not found"))
                .flatMap(remoteHeader =>
                  core.consensus.localChain.currentHead.flatMap(currentHeadId =>
                    if (remoteHeader.parentHeaderId == currentHeadId)
                      checkHeader(remoteHeader) >> fetchFullBlock(remoteHeader)
                        .flatTap(checkBody)
                        .flatTap(adoptAndLog)
                        .as(true)
                    else
                      Logger[F].info(show"Block id=$blockId is not a direct local extension.  Checking sync.").as(false)
                  )
                )
            )
      )
      .iterateWhile(identity)
      .void

  private def mempoolSync: F[Unit] =
    interface.nextTransactionNotification
      .flatMap(id =>
        core.dataStores.transactions
          .contains(id)
          .ifM(
            ().pure[F],
            OptionT(interface.fetchTransaction(id))
              .getOrRaise(new IllegalStateException("Remote peer did not have expected transaction"))
              .flatMap(core.ledger.mempool.add)
          )
      )
      .foreverM

  private def sync(commonAncestor: BlockHeader): F[Unit] =
    Stream
      .unfold(commonAncestor.height + 1)(v => Some(v, v + 1))
      .parEvalMap(32)(interface.blockIdAtHeight)
      .unNoneTerminate
      .parEvalMap(128)(id =>
        OptionT(interface.fetchHeader(id))
          .getOrRaise(new IllegalArgumentException("Remote header not found"))
      )
      .through(noForks)
      .through(fetchVerifyPersistPipe)
      .through(adoptSparsely)
      .compile
      .drain

  private def fetchVerifyPersistPipe: Pipe[F, BlockHeader, FullBlock] =
    _.evalTap(checkHeader)
      .parEvalMap(16)(fetchFullBlock)
      .evalTap(checkBody)

  private def checkHeader(header: BlockHeader): F[Unit] =
    for {
      _ <- Logger[F].info(show"Processing remote block id=${header.id}")
      _ <- core.consensus.headerValidation
        .validate(header)
        .leftMap(errors => new IllegalArgumentException(errors.head))
        .rethrowT
      _ <- core.dataStores.headers.put(header.id, header)
      _ <- core.blockIdTree.associate(header.id, header.parentHeaderId)
    } yield ()

  private def fetchFullBlock(header: BlockHeader): F[FullBlock] =
    for {
      parentHeader <- core.dataStores.headers.getOrRaise(header.parentHeaderId)
      body <- OptionT(core.dataStores.bodies.get(header.id))
        .orElse(
          OptionT(interface.fetchBody(header.id))
            .ensure(new IllegalArgumentException("TxRoot Mismatch"))(body =>
              body.transactionIds.txRoot(parentHeader.txRoot.decodeBase58) == header.txRoot.decodeBase58
            )
        )
        .getOrRaise(new IllegalArgumentException("Remote body not found"))
      transactions <- Stream
        .iterable(body.transactionIds)
        .parEvalMap(16)(id =>
          OptionT(core.dataStores.transactions.get(id))
            .orElse(OptionT(interface.fetchTransaction(id)))
            .getOrRaise(new IllegalArgumentException("Remote transaction not found"))
        )
        .compile
        .toList
      fullBody = FullBlockBody(transactions)
    } yield FullBlock(header, fullBody)

  private def checkBody(fullBlock: FullBlock): F[Unit] =
    for {
      _ <- core.ledger.bodyValidation
        .validate(
          fullBlock.fullBody,
          TransactionValidationContext(
            fullBlock.header.parentHeaderId,
            fullBlock.header.height,
            fullBlock.header.slot
          )
        )
        .leftMap(errors => new IllegalArgumentException(errors.head))
        .rethrowT
      body = BlockBody(fullBlock.fullBody.transactions.map(_.id))
      _ <- core.dataStores.bodies
        .contains(fullBlock.header.id)
        .ifM(().pure[F], core.dataStores.bodies.put(fullBlock.header.id, body))
      _ <- fullBlock.fullBody.transactions.traverseTap(transaction =>
        core.dataStores.transactions
          .contains(transaction.id)
          .ifM(().pure[F], core.dataStores.transactions.put(transaction.id, transaction))
      )
    } yield ()

  private def adoptAndLog(fullBlock: FullBlock): F[Unit] =
    core.consensus.localChain.adopt(fullBlock.header.id) >>
      Logger[F].info(
        show"Adopted block" +
          show" id=${fullBlock.header.id}" +
          show" height=${fullBlock.header.height}" +
          show" slot=${fullBlock.header.slot}" +
          show" transactions=${fullBlock.fullBody.transactions.map(_.id)}"
      )

  private def noForks: Pipe[F, BlockHeader, BlockHeader] = {
    def start(s: Stream[F, BlockHeader]): Pull[F, BlockHeader, Unit] =
      s.pull.uncons1.flatMap {
        case Some((head, tail)) =>
          Pull.output1(head) >> go(tail, head)
        case None =>
          Pull.done
      }

    def go(
        s: Stream[F, BlockHeader],
        previous: BlockHeader
    ): Pull[F, BlockHeader, Unit] =
      s.pull.uncons1.flatMap {
        case Some((head, tlStream)) =>
          if (head.parentHeaderId != previous.id)
            Pull.raiseError(new IllegalStateException("Remote peer branched during sync"))
          else Pull.output1(head) >> go(tlStream, head)
        case None =>
          Pull.done
      }

    start(_).stream
  }

  private def adoptSparsely: Pipe[F, FullBlock, FullBlock] = {
    val epochThirdLength = core.clock.epochLength / 3L
    def start(s: Stream[F, FullBlock]): Pull[F, FullBlock, Unit] =
      s.pull.uncons1.flatMap {
        case Some((head, tail)) =>
          Pull.output1(head) >> go(tail, head, false, head.header.slot / epochThirdLength)
        case None =>
          Pull.done
      }

    def go(
        s: Stream[F, FullBlock],
        previous: FullBlock,
        previousWasAdopted: Boolean,
        lastAdoptedThird: Long
    ): Pull[F, FullBlock, Unit] =
      s.pull.uncons1.flatMap {
        case Some((head, tail)) =>
          val third = head.header.slot / epochThirdLength
          if (third != lastAdoptedThird)
            Pull.eval(adoptAndLog(head)) >> Pull.output1(head) >> go(tail, head, true, third)
          else
            Pull.output1(head) >> go(tail, head, false, lastAdoptedThird)
        case None =>
          if (previousWasAdopted) Pull.done
          else Pull.eval(adoptAndLog(previous)) >> Pull.done
      }

    start(_).stream
  }
