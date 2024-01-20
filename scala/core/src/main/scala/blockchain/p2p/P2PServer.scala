package blockchain.p2p

import blockchain.BlockchainCore
import blockchain.codecs.given
import cats.effect.Async
import cats.implicits.*
import cats.effect.implicits.*
import cats.effect.kernel.{Outcome, Resource}
import cats.effect.std.{Queue, Random}
import com.comcast.ip4s.{Host, Port, SocketAddress}
import fs2.io.net.{Network, Socket}
import fs2.Stream
import org.typelevel.log4cats.slf4j.Slf4jLogger

class P2PServer[F[_]] {}

object P2PServer:
  def serve[F[_]: Async](
      bindHost: String,
      bindPort: Int,
      handleSocket: (Socket[F], Option[SocketAddress[_]]) => F[Unit],
      outboundConnections: Stream[F, SocketAddress[_]]
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
      inboundSockets = network.server(h.some, p.some)
      inboundHandler = inboundSockets
        .evalTap(socket => socket.remoteAddress.flatTap(address => logger.info(show"Inbound connection from $address")))
        .map(socket => Stream.eval(handleSocket(socket, None)))
        .parJoinUnbounded
        .compile
        .drain
      outboundHandler = outboundConnections
        .evalTap(address => logger.info(show"Outbound connection to $address"))
        .map(address => Stream.eval(network.client(address).use(handleSocket(_, address.some))))
        .parJoinUnbounded
        .compile
        .drain
      outcome <- (inboundHandler, outboundHandler).parTupled.void.background
    } yield outcome

  def serveBlockchain[F[_]: Async: Random](
      core: BlockchainCore[F],
      bindHost: String,
      bindPort: Int,
      publicHost: Option[String],
      publicPort: Option[Int],
      magicBytes: Array[Byte],
      initialPeers: List[SocketAddress[_]]
  ): Resource[F, F[Outcome[F, Throwable, Unit]]] =
    Slf4jLogger
      .fromName("P2P")
      .toResource
      .flatMap(logger =>
        Resource
          .onFinalize(logger.info("P2P Terminated")) >> (
          Queue.unbounded[F, SocketAddress[_]].flatTap(queue => initialPeers.traverse(queue.offer)).toResource,
          LocalPeer
            .make(core, publicHost, publicPort)
            .evalTap(localPeer => logger.info(show"Local peer id=${localPeer.connectedPeer.peerId}"))
        ).tupled
          .flatMap((outboundConnectionsQueue, localPeer) =>
            PeersManager
              .make(core, localPeer, magicBytes, outboundConnectionsQueue.offer(_).void, initialPeers)
              .flatMap(manager =>
                serve(bindHost, bindPort, manager.handleSocket, Stream.fromQueueUnterminated(outboundConnectionsQueue))
              )
          )
          .evalTap(_ =>
            logger.info(
              s"Serving P2P on binding=$bindHost:$bindPort public=${publicHost.getOrElse("")}${publicPort.fold("")(":" + _)}"
            )
          )
      )
