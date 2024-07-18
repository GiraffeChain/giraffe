package blockchain.p2p

import blockchain.BlockchainCore
import blockchain.codecs.given
import blockchain.crypto.CryptoResources
import cats.effect.Async
import cats.effect.implicits.*
import cats.effect.kernel.{Outcome, Resource}
import cats.effect.std.Random
import cats.implicits.*
import com.comcast.ip4s.{Host, Port, SocketAddress}
import fs2.Stream
import fs2.concurrent.Channel
import fs2.io.net.{Network, Socket, SocketOption}
import org.typelevel.log4cats.slf4j.Slf4jLogger

import scala.concurrent.duration.*

object P2PServer:
  def serve[F[_]: Async](
      bindHost: String,
      bindPort: Int,
      handleSocket: (Socket[F], Option[SocketAddress[?]]) => F[Unit],
      outboundConnections: Stream[F, SocketAddress[?]]
  ): Resource[F, F[Outcome[F, Throwable, Unit]]] =
    for {
      logger <- Slf4jLogger.fromName("P2P").toResource
      h <- Host
        .fromString(bindHost)
        .toRight(new IllegalArgumentException("BindHost"))
        .pure[F]
        .rethrow
        .toResource
      p <- Port
        .fromInt(bindPort)
        .toRight(new IllegalArgumentException("BindPort"))
        .pure[F]
        .rethrow
        .toResource
      network = Network.forAsync[F]
      inboundSockets = network.server(h.some, p.some, socketOptions)
      inboundHandler = inboundSockets
        .evalTap(socket => socket.remoteAddress.flatTap(address => logger.info(show"Inbound connection from $address")))
        .map(socket => Stream.exec(handleSocket(socket, None)))
        .parJoinUnbounded
      outboundHandler = outboundConnections
        .evalTap(address => logger.info(show"Outbound connection to $address"))
        .map(address =>
          Stream.exec(
            network
              .client(address, socketOptions)
              .timeout(5.seconds)
              .use(handleSocket(_, address.some))
          )
        )
        .parJoinUnbounded
      handler = inboundHandler.merge(outboundHandler).compile.drain
      outcome <- handler.void.background
    } yield outcome

  def serveBlockchain[F[_]: Async: Random: CryptoResources](
      core: BlockchainCore[F],
      bindHost: String,
      bindPort: Int,
      publicHost: Option[String],
      publicPort: Option[Int],
      magicBytes: Array[Byte],
      initialPeers: List[SocketAddress[?]]
  ): Resource[F, F[Outcome[F, Throwable, Unit]]] =
    Slf4jLogger
      .fromName("P2P")
      .toResource
      .flatMap(logger =>
        Resource
          .onFinalize(logger.info("P2P Terminated")) >> (
          Resource
            .make(Channel.unbounded[F, SocketAddress[?]])(_.close.void)
            .evalTap(channel => initialPeers.traverse(channel.send)),
          LocalPeer
            .make(core, publicHost, publicPort)
            .evalTap(localPeer => logger.info(show"Local peer id=${localPeer.connectedPeer.peerId}"))
        ).tupled
          .flatMap((outboundConnectionsChannel, localPeer) =>
            PeersManager
              .make(core, localPeer, magicBytes, outboundConnectionsChannel.send(_).void, initialPeers)
              .flatMap(manager => serve(bindHost, bindPort, manager.handleSocket, outboundConnectionsChannel.stream))
          )
          .evalTap(_ =>
            logger.info(
              s"Serving P2P on binding=$bindHost:$bindPort public=${publicHost.getOrElse("")}${publicPort.fold("")(":" + _)}"
            )
          )
      )

  private val socketOptions = List(SocketOption.noDelay(true), SocketOption.keepAlive(true))
