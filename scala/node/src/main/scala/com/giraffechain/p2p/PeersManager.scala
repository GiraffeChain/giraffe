package com.giraffechain.p2p

import cats.data.OptionT
import cats.effect.implicits.*
import cats.effect.std.Random
import cats.effect.{Async, Deferred, Ref, Resource}
import cats.implicits.*
import com.comcast.ip4s.{Host, Port, SocketAddress}
import com.giraffechain.BlockchainCore
import com.giraffechain.codecs.given
import com.giraffechain.crypto.CryptoResources
import com.giraffechain.models.*
import fs2.Stream
import fs2.io.net.Socket
import org.typelevel.log4cats.Logger
import org.typelevel.log4cats.slf4j.Slf4jLogger

import scala.concurrent.duration.*

class PeersManager[F[_]: Async: Random: CryptoResources](
    core: BlockchainCore[F],
    sharedSync: SharedSync[F],
    localPeer: LocalPeer,
    magicBytes: Array[Byte],
    connectOutbound: SocketAddress[?] => F[Unit],
    stateRef: Ref[F, PeersManager.State[F]]
):

  private given logger: Logger[F] = Slf4jLogger.getLoggerFromName("PeersManager")

  def close(): F[Unit] =
    stateRef
      .getAndSet(PeersManager.State(Map.empty, Map.empty, Nil))
      .flatMap(state => state.connectedPeers.values.toList.traverse(_.close()))
      .void

  def connectNext(): F[Unit] = (
    for {
      state <- stateRef.get
      candidates <- state.connectedPeers.values.toList
        .traverse(
          _.publicStateRef.get.map(
            _.peers.flatMap(p =>
              (p.host.flatMap(Host.fromString), p.port.flatMap(Port.fromInt))
                .mapN(SocketAddress.apply)
                .tupleLeft(p.peerId)
            )
          )
        )
        .map(
          _.flatten.toMap
            .removed(localPeer.connectedPeer.peerId)
            .removedAll(state.connectedPeers.keys)
            .values
            .toList
        )
      _ <-
        if (candidates.nonEmpty)
          Random[F].elementOf(candidates).flatMap(connectOutbound)
        else if (state.connectedPeers.isEmpty && state.knownPeers.nonEmpty)
          Random[F].elementOf(state.knownPeers).flatMap(connectOutbound)
        else
          ().pure[F]
    } yield ()
  ).handleError(e => Logger[F].warn(e)("Failed to connect to new peer"))

  def handleSocket(socket: Socket[F], outboundAddress: Option[SocketAddress[?]]): F[Unit] = {
    val resource = for {
      _ <- Resource.onFinalize(socket.endOfInput *> socket.endOfOutput)
      remotePeerId <- Handshake.run(socket, magicBytes, localPeer.sk, localPeer.vk).timeout(5.seconds).toResource
      _ <- Async[F]
        .raiseWhen(remotePeerId == localPeer.connectedPeer.peerId)(
          new IllegalStateException("Self-Connection")
        )
        .toResource
      given Logger[F] <- Slf4jLogger.fromName(show"Peer($remotePeerId)").toResource
      previousConnection <- stateRef.get.map(_.connectedPeers.get(remotePeerId)).toResource
      _ <- previousConnection
        .traverse(c => Logger[F].warn(show"Duplicate Connection id=$remotePeerId. Closing previous.") *> c.abort)
        .toResource
      _ <- Resource.make(Logger[F].info("Connected"))(_ => Logger[F].info("Disconnected"))
      // TODO: This is only expected to be used in the case of duplicate connections, but it's available so could
      // be accidentally abused
      abortSwitch <- Deferred[F, Unit].toResource
      peerState <- PeerState.make(
        socket,
        core,
        this,
        PublicP2PState(localPeer = ConnectedPeer(remotePeerId)),
        outboundAddress,
        Async[F].defer(abortSwitch.complete(()).void)
      )
      _ <- stateRef.update(_.withConnectedPeer(remotePeerId, peerState)).toResource
      _ <- Resource.onFinalize(
        sharedSync.omitPeer(remotePeerId) *>
          OptionT(abortSwitch.tryGet)
            .flatTapNone(
              stateRef.update(_.withDisconnectedPeer(remotePeerId, peerState))
            )
            .value
            .void
      )
      handler = new PeerBlockchainHandler[F](core, peerState, sharedSync)
      _ <- peerState.interface.background
        .mergeHaltBoth(handler.handle)
        .mergeHaltBoth(Stream.exec(abortSwitch.get))
        .compile
        .drain
        .toResource
    } yield ()

    resource.use_.handleErrorWith(e => logger.warn(e)("Connection error"))
  }

  def currentState: F[PublicP2PState] =
    stateRef.get
      .flatMap(
        _.connectedPeers.values.toList
          .traverse(_.publicStateRef.get.map(_.localPeer))
      )
      .map(PublicP2PState(localPeer.connectedPeer, _))

object PeersManager:

  def make[F[_]: Async: Random: CryptoResources](
      core: BlockchainCore[F],
      localPeer: LocalPeer,
      magicBytes: Array[Byte],
      connectOutbound: SocketAddress[?] => F[Unit],
      knownPeers: List[SocketAddress[?]]
  ): Resource[F, PeersManager[F]] =
    Ref
      .of(State[F](Map.empty, Map.empty, knownPeers))
      .toResource
      .flatMap(stateRef =>
        SharedSync
          .make(core, stateRef.get.map(_.connectedPeers.view.mapValues(_.interface).toMap))
          .map(
            new PeersManager(
              core,
              _,
              localPeer,
              magicBytes,
              connectOutbound,
              stateRef
            )
          )
      )
      .flatTap(manager => Resource.onFinalize(Async[F].defer(manager.close())))
      .flatTap(manager =>
        Stream
          .awakeDelay(10.seconds)
          .evalTap(_ => manager.connectNext())
          .compile
          .drain
          .background
      )

  case class State[F[_]](
      connectedPeers: Map[PeerId, PeerState[F]],
      disconnectedPeers: Map[PeerId, PeerState[F]],
      knownPeers: List[SocketAddress[?]]
  ):
    def withConnectedPeer(peerId: PeerId, peerState: PeerState[F]): State[F] =
      copy(
        connectedPeers = connectedPeers.updated(peerId, peerState),
        disconnectedPeers = disconnectedPeers.removed(peerId)
      )
    def withDisconnectedPeer(peerId: PeerId, peerState: PeerState[F]): State[F] =
      copy(
        connectedPeers = connectedPeers.removed(peerId),
        disconnectedPeers = disconnectedPeers.updated(peerId, peerState)
      )
