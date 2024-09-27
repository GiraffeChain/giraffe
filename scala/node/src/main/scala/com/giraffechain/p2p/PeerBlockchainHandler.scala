package com.giraffechain.p2p

import cats.MonadThrow
import cats.data.OptionT
import cats.effect.Async
import cats.effect.implicits.*
import cats.effect.std.Random
import cats.implicits.*
import com.giraffechain.*
import com.giraffechain.codecs.{*, given}
import com.giraffechain.ledger.*
import com.giraffechain.models.*
import com.google.protobuf.ByteString
import fs2.Stream
import org.typelevel.log4cats.Logger

import scala.concurrent.duration.*

class PeerBlockchainHandler[F[_]: Async: Logger: Random](
    core: BlockchainCore[F],
    remotePeerState: PeerState[F],
    sharedSync: SharedSync[F]
):
  def handle: Stream[F, Unit] =
    pingPong.merge(peerState).mergeHaltR(Stream.exec(start))

  private def interface = remotePeerState.interface

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
      commonAncestorHeader <- core.dataStores.headers.getOrRaise(commonAncestorId)
      remoteHeadId <- OptionT(interface.blockIdAtHeight(0))
        .getOrRaise(new IllegalArgumentException("No Canonical Head"))
      remoteHeader <- OptionT(interface.fetchHeader(remoteHeadId))
        .getOrRaise(new IllegalArgumentException("No Canonical Head"))
      _ <- sharedSync.compare(commonAncestorHeader, remoteHeader, remotePeerState.peerId)
      _ <- inSync
    } yield ()

  private def inSync: F[Unit] =
    awaitBetterBlock
      .race(mempoolSync)
      // If the sync process completes with error, eagerly return to the sync check loop
      .race((sharedSync.syncCompletion >> Async[F].never).voidError)
      .void

  private def awaitBetterBlock: F[Unit] =
    interface.nextBlockAdoption
      .flatMap(blockId =>
        Logger[F].debug(show"Received block notification id=$blockId") >>
          core.dataStores.headers
            .contains(blockId)
            .ifM(
              Logger[F].debug(show"Ignoring known block id=$blockId").as(true),
              OptionT(interface.fetchHeader(blockId))
                .getOrRaise(new IllegalArgumentException("Remote header not found"))
                .flatMap(remoteHeader =>
                  core.consensus.localChain.currentHead.flatMap(currentHeadId =>
                    if (remoteHeader.parentHeaderId == currentHeadId)
                      PeerBlockchainHandler.checkHeader(core)(remoteHeader) >>
                        PeerBlockchainHandler
                          .fetchFullBlock(core, interface, 1)(remoteHeader)
                          .flatTap(PeerBlockchainHandler.checkBody(core))
                          .flatTap(PeerBlockchainHandler.adoptAndLog(core))
                          .as(true)
                    else
                      Logger[F]
                        .debug(show"Block id=$blockId is not a direct local extension.  Checking sync.")
                        .as(false)
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

object PeerBlockchainHandler:

  def checkHeader[F[_]: Async: Logger](core: BlockchainCore[F])(header: BlockHeader): F[Unit] =
    for {
      _ <- Logger[F].info(show"Processing remote block id=${header.id}")
      _ <- core.consensus.headerValidation
        .validate(header)
        .leftMap(errors => new IllegalArgumentException(errors.head))
        .rethrowT
      _ <- core.dataStores.headers
        .put(header.id, header) &> core.blockIdTree.associate(header.id, header.parentHeaderId)
    } yield ()

  def fetchFullBlock[F[_]: Async](
      core: BlockchainCore[F],
      interface: PeerBlockchainInterface[F],
      parallelismScale: Int
  )(
      header: BlockHeader
  ): F[FullBlock] =
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
        .emits(body.transactionIds)
        .parEvalMap(2 * parallelismScale)(id =>
          OptionT(core.dataStores.transactions.get(id))
            .orElse(OptionT(interface.fetchTransaction(id)))
            .getOrRaise(new IllegalArgumentException("Remote transaction not found"))
        )
        .compile
        .toList
      fullBody = FullBlockBody(transactions)
    } yield FullBlock(header, fullBody)

  def checkBody[F[_]: MonadThrow](core: BlockchainCore[F])(fullBlock: FullBlock): F[Unit] =
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

  def adoptAndLog[F[_]: MonadThrow: Logger](core: BlockchainCore[F])(fullBlock: FullBlock): F[Unit] =
    core.consensus.localChain.adopt(fullBlock.header.id) >>
      Logger[F].info(
        show"Adopted block" +
          show" id=${fullBlock.header.id}" +
          show" height=${fullBlock.header.height}" +
          show" slot=${fullBlock.header.slot}" +
          show" transactions=${fullBlock.fullBody.transactions.map(_.id)}"
      )
