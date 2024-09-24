package com.giraffechain.p2p

import cats.data.OptionT
import cats.effect.implicits.*
import cats.effect.std.{Mutex, Random}
import cats.effect.{Async, Fiber, Ref, Resource}
import cats.implicits.*
import com.giraffechain.codecs.given
import com.giraffechain.consensus.ChainSelectionOutcome
import com.giraffechain.models.*
import com.giraffechain.{BlockchainCore, Height}
import fs2.{Pipe, Pull, Stream}
import org.typelevel.log4cats.Logger
import org.typelevel.log4cats.slf4j.Slf4jLogger

class SharedSync[F[_]: Async: Random](
    core: BlockchainCore[F],
    clientsF: F[Map[PeerId, PeerBlockchainInterface[F]]],
    stateRef: Ref[F, Option[SharedSyncState[F]]],
    mutex: Mutex[F]
):

  private given logger: Logger[F] =
    Slf4jLogger.getLoggerFromName("SharedSync")

  def compare(commonAncestorHeader: BlockHeader, target: BlockHeader, peerId: PeerId): F[Unit] =
    OptionT(stateRef.get).foldF(
      localCompare(commonAncestorHeader, target, peerId)
    )(state =>
      if (state.target.id == target.id || state.target.id == target.parentHeaderId)
        updateTarget(commonAncestorHeader, target, peerId).void
      else remoteCompare(commonAncestorHeader, target, peerId)(state.target, state.providers)
    )

  def omitPeer(peerId: PeerId): F[Unit] =
    stateRef.modify {
      case Some(state) if state.providers == Set(peerId) =>
        (none, state.fiber.cancel)
      case Some(state) if state.providers.contains(peerId) =>
        (state.copy(providers = state.providers - peerId).some, ().pure[F])
      case s =>
        (s, ().pure[F])
    }

  private def localCompare(commonAncestorHeader: BlockHeader, target: BlockHeader, peerId: PeerId) =
    mutex.lock
      .surround(
        for {
          interface <- clientsF.map(_.apply(peerId))
          remoteHeaderAtHeightF = (height: Height) =>
            OptionT(interface.blockIdAtHeight(height)).flatMapF(interface.fetchHeader).value
          localHeadId <- core.consensus.localChain.currentHead
          localHeader <- core.dataStores.headers.getOrRaise(localHeadId)
          localHeaderAtHeightF = (height: Height) =>
            OptionT(core.consensus.localChain.blockIdAtHeight(height)).flatMapF(core.dataStores.headers.get).value
          chainSelectionResult <- core.consensus.chainSelection.compare(
            localHeader,
            target,
            commonAncestorHeader,
            localHeaderAtHeightF,
            remoteHeaderAtHeightF
          )
          _ <- logResult(chainSelectionResult)
          newStateOpt <- OptionT
            .whenF(chainSelectionResult.isY)(updateTarget(commonAncestorHeader, target, peerId))
            .value
        } yield newStateOpt
      )
      .void

  private def remoteCompare(commonAncestorHeader: BlockHeader, target: BlockHeader, peerId: PeerId)(
      currentTarget: BlockHeader,
      providers: Set[PeerId]
  ) =
    mutex.lock
      .surround(
        for {
          clients <- clientsF
          interface = clients(peerId)
          remoteHeaderAtHeightF = (height: Height) =>
            OptionT(interface.blockIdAtHeight(height)).flatMapF(interface.fetchHeader).value
          localInterface = MultiPeerInterface[F](providers.map(clients).toList)
          localHeaderAtHeightF = (height: Height) =>
            OptionT(localInterface.blockIdAtHeight(height)).flatMapF(localInterface.fetchHeader).value
          chainSelectionResult <- core.consensus.chainSelection.compare(
            currentTarget,
            target,
            commonAncestorHeader,
            localHeaderAtHeightF,
            remoteHeaderAtHeightF
          )
          _ <- logResult(chainSelectionResult)
          newStateOpt <- OptionT
            .whenF(chainSelectionResult.isY)(updateTarget(commonAncestorHeader, target, peerId))
            .value
        } yield newStateOpt
      )
      .void

  private def logResult(chainSelectionResult: ChainSelectionOutcome) =
    chainSelectionResult match {
      case ChainSelectionOutcome.XStandard =>
        Logger[F].info("Remote peer is up-to-date but local chain is better")
      case ChainSelectionOutcome.YStandard =>
        Logger[F].info("Local peer is up-to-date but remote chain is better")
      case ChainSelectionOutcome.XDensity =>
        Logger[F].info("Remote peer is out-of-sync but local chain is better")
      case ChainSelectionOutcome.YDensity =>
        Logger[F].info("Local peer out-of-sync and remote chain is better")
    }

  private def updateTarget(commonAncestor: BlockHeader, target: BlockHeader, provider: PeerId): F[SharedSyncState[F]] =
    stateRef.get
      .flatMap {
        case Some(s @ SharedSyncState(current, providers, _)) if current.id == target.id =>
          s.copy(providers = providers + provider).pure[F]
        case Some(s @ SharedSyncState(current, _, _)) if current.id == target.parentHeaderId =>
          s.copy(target = target, providers = Set(provider)).pure[F]
        case _ =>
          sync(commonAncestor).start
            .map(fiber => SharedSyncState(target, Set(provider), fiber))
      }
      .flatTap(state => stateRef.set(state.some))

  private def sync(commonAncestor: BlockHeader): F[Unit] =
    Stream
      .unfoldEval(commonAncestor.height + 1)(h =>
        OptionT(stateRef.get)
          .map(_.target)
          .filter(_.height >= h)
          .as((h, h + 1))
          .value
      )
      .chunkLimit(2048)
      .evalMap(heights =>
        for {
          clients <- clientsF
          lastHeight = heights.last.get
          SharedSyncState(_, providers, _) <- OptionT(stateRef.get).getOrRaise(
            new IllegalStateException("Target not set")
          )
          providerInterfaces = providers.map(clients).toList
          providersInterface = MultiPeerInterface[F](providerInterfaces)
          batchTargetId <- OptionT(providersInterface.blockIdAtHeight(lastHeight)).getOrRaise(
            new IllegalStateException("Target not found")
          )
          alternativeClients <- (clients -- providers).values.toList.traverseFilter(client =>
            OptionT(client.blockIdAtHeight(lastHeight)).filter(_ == batchTargetId).as(client).value
          )
          interface = MultiPeerInterface[F](providerInterfaces ++ alternativeClients)
        } yield (heights, interface)
      )
      .flatMap((heights, interface) =>
        Stream
          .chunk(heights)
          .parEvalMap(32)(height =>
            OptionT(interface.blockIdAtHeight(height)).getOrRaise(
              new IllegalStateException("Block at Height not found")
            )
          )
          .parEvalMap(128)(id =>
            OptionT(interface.fetchHeader(id))
              .getOrRaise(new IllegalArgumentException("Remote header not found"))
          )
          .through(noForks)
          .through(fetchVerifyPersistPipe(interface))
      )
      .through(adoptSparsely)
      .compile
      .drain >> stateRef.set(none)

  private def fetchVerifyPersistPipe(interface: PeerBlockchainInterface[F]): Pipe[F, BlockHeader, FullBlock] =
    _.evalTap(PeerBlockchainHandler.checkHeader(core))
      .parEvalMap(16)(PeerBlockchainHandler.fetchFullBlock(core, interface))
      .evalTap(PeerBlockchainHandler.checkBody(core))

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
            Pull.eval(PeerBlockchainHandler.adoptAndLog(core)(head)) >> Pull
              .output1(head) >> go(tail, head, true, third)
          else
            Pull.output1(head) >> go(tail, head, false, lastAdoptedThird)
        case None =>
          if (previousWasAdopted) Pull.done
          else Pull.eval(PeerBlockchainHandler.adoptAndLog(core)(previous)) >> Pull.done
      }

    start(_).stream
  }

object SharedSync:
  def make[F[_]: Async: Random](
      core: BlockchainCore[F],
      clientsF: F[Map[PeerId, PeerBlockchainInterface[F]]]
  ): Resource[F, SharedSync[F]] =
    (
      Resource.make(Ref.of[F, Option[SharedSyncState[F]]](None))(
        _.getAndSet(none).flatMap(_.traverse(_.fiber.cancel)).void
      ),
      Mutex[F].toResource
    )
      .mapN(new SharedSync(core, clientsF, _, _))

case class SharedSyncState[F[_]](target: BlockHeader, providers: Set[PeerId], fiber: Fiber[F, Throwable, Unit])
