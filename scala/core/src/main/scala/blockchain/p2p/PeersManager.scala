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

class PeersManager[F[_]: Async: Random](
    core: BlockchainCore[F],
    localPeer: LocalPeer,
    magicBytes: Array[Byte],
    connectOutbound: SocketAddress[_] => F[Unit],
    stateRef: Ref[F, PeersManager.State[F]]
):

  private given logger: Logger[F] = Slf4jLogger.getLoggerFromName("PeersManager")

  def close(): F[Unit] =
    stateRef
      .getAndSet(PeersManager.State(Map.empty, Map.empty))
      .flatMap(state => state.connectedPeers.values.toList.traverse(_.close()))
      .void

  def connectNext(): F[Unit] =
    for {
      state <- stateRef.get
      targets <- state.connectedPeers.values.toList
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
      _ <- Async[F].whenA(targets.nonEmpty)(
        Random[F].elementOf(targets).flatMap(connectOutbound)
      )
    } yield ()

  def handleSocket(socket: Socket[F]): F[Unit] = {
    val resource = for {
      _ <- Resource.onFinalize(socket.endOfInput *> socket.endOfOutput)
      given CryptoResources[F] = core.cryptoResources
      remotePeerId <- Handshake
        .run(socket, magicBytes, localPeer.sk, localPeer.vk)
        .toResource
      given Logger[F] <- Slf4jLogger
        .fromName(show"Peer($remotePeerId)")
        .toResource
      _ <- Resource.make(Logger[F].info("Connected"))(_ => Logger[F].info("Disconnected"))
      peerState <- PeerState.make(
        socket,
        PublicP2PState(localPeer = ConnectedPeer(remotePeerId))
      )
      _ <- Resource.make(
        stateRef.update(_.withConnectedPeer(remotePeerId, peerState))
      )(_ => stateRef.update(_.withDisconnectedPeer(remotePeerId, peerState)))
      portQueues <- AllPortQueues.make[F]
      readerWriter = MultiplexedReaderWriter.forSocket(socket)
      interface = new PeerBlockchainInterface[F](
        core,
        peerState,
        this,
        portQueues,
        readerWriter
      )
      handler = new PeerBlockchainHandler[F](
        core,
        interface,
        onPeerStateGossiped(remotePeerId, _)
      )
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

  def onPeerStateGossiped(peerId: PeerId, publicState: PublicP2PState) =
    stateRef.get.flatMap(
      _.connectedPeers(peerId).publicStateRef.set(publicState)
    )

object PeersManager:

  def make[F[_]: Async: Random](
      core: BlockchainCore[F],
      localPeer: LocalPeer,
      magicBytes: Array[Byte],
      connectOutbound: SocketAddress[_] => F[Unit]
  ): Resource[F, PeersManager[F]] =
    Ref
      .of(State[F](Map.empty, Map.empty))
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
          .awakeDelay(30.seconds)
          .evalTap(_ => manager.connectNext())
          .compile
          .drain
          .background
      )

  case class State[F[_]](
      connectedPeers: Map[PeerId, PeerState[F]],
      disconnectedPeers: Map[PeerId, PeerState[F]]
  ):
    def withConnectedPeer(peerId: PeerId, peerState: PeerState[F]) =
      copy(
        connectedPeers = connectedPeers.updated(peerId, peerState),
        disconnectedPeers = disconnectedPeers.removed(peerId)
      )
    def withDisconnectedPeer(peerId: PeerId, peerState: PeerState[F]) =
      copy(
        connectedPeers = connectedPeers.removed(peerId),
        disconnectedPeers = disconnectedPeers.updated(peerId, peerState)
      )
