package blockchain.p2p

import blockchain.BlockchainCore
import blockchain.codecs.given
import blockchain.crypto.CryptoResources
import blockchain.models.*
import cats.effect.implicits.*
import cats.effect.std.Random
import cats.effect.{Async, Ref, Resource}
import cats.implicits.*
import com.comcast.ip4s.{Host, Port, SocketAddress}
import fs2.Stream
import fs2.io.net.Socket
import org.typelevel.log4cats.Logger
import org.typelevel.log4cats.slf4j.Slf4jLogger

import scala.concurrent.duration.*

class PeersManager[F[_]: Async: Random: CryptoResources](
    core: BlockchainCore[F],
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

  def connectNext(): F[Unit] =
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

  def handleSocket(socket: Socket[F], outboundAddress: Option[SocketAddress[?]]): F[Unit] = {
    val resource = for {
      _ <- Resource.onFinalize(socket.endOfInput *> socket.endOfOutput)
      remotePeerId <- Handshake.run(socket, magicBytes, localPeer.sk, localPeer.vk).timeout(5.seconds).toResource
      given Logger[F] <- Slf4jLogger.fromName(show"Peer($remotePeerId)").toResource
      _ <- Resource.make(Logger[F].info("Connected"))(_ => Logger[F].info("Disconnected"))
      peerState <- PeerState.make(socket, PublicP2PState(localPeer = ConnectedPeer(remotePeerId)), outboundAddress)
      _ <- Async[F]
        .raiseWhen(remotePeerId == localPeer.connectedPeer.peerId)(
          new IllegalStateException("Self-Connection")
        )
        .toResource
      isNewPeer <- Resource.make(
        stateRef.modify(s =>
          if (s.connectedPeers.contains(remotePeerId)) (s, false)
          else (s.withConnectedPeer(remotePeerId, peerState), true)
        )
      )(_ => stateRef.update(_.withDisconnectedPeer(remotePeerId, peerState)))
      _ <- Async[F].raiseWhen(!isNewPeer)(new IllegalStateException("Duplicate Connection")).toResource
      portQueues <- AllPortQueues.make[F]
      readerWriter <- MultiplexedReaderWriter.forSocket(socket)
      peerCache <- PeerCache.make[F]
      interface = new PeerBlockchainInterface[F](core, this, portQueues, readerWriter, peerCache)
      handler = new PeerBlockchainHandler[F](core, interface, peerState)
      _ <- interface.background.merge(handler.handle).compile.drain.toResource
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
      .map(
        new PeersManager(
          core,
          localPeer,
          magicBytes,
          connectOutbound,
          _
        )
      )
      .toResource
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
