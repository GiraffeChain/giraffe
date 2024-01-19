package blockchain.p2p

import cats.effect.Async
import cats.implicits.*
import cats.effect.implicits.*
import cats.effect.kernel.{Outcome, Resource}
import com.comcast.ip4s.{Host, Port, SocketAddress}
import fs2.io.net.{Network, Socket}
import fs2.Stream

class P2PServer[F[_]] {}

object P2PServer:
  def serve[F[_]: Async](
      bindHost: String,
      bindPort: Int,
      handleSocket: Socket[F] => F[Unit],
      outboundConnections: Stream[F, SocketAddress[_]]
  ): Resource[F, F[Outcome[F, Throwable, Unit]]] =
    for {
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
        .map(socket => Stream.eval(handleSocket(socket)))
        .parJoinUnbounded
        .compile
        .drain
      outboundHandler = outboundConnections
        .map(address => Stream.eval(network.client(address).use(handleSocket)))
        .parJoinUnbounded
        .compile
        .drain
      outcome <- (inboundHandler, outboundHandler).parTupled.void.background
    } yield outcome
