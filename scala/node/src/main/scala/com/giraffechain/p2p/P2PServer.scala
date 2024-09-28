package com.giraffechain.p2p

import com.giraffechain.BlockchainCore
import com.giraffechain.codecs.given
import com.giraffechain.crypto.CryptoResources
import cats.data.OptionT
import cats.effect.Async
import cats.effect.implicits.*
import cats.effect.kernel.{Outcome, Resource}
import cats.effect.std.Random
import cats.implicits.*
import com.comcast.ip4s.{Host, Port, SocketAddress}
import fs2.Stream
import fs2.concurrent.Channel
import fs2.io.net.{Network, Socket, SocketOption}
import org.http4s.ember.client.EmberClientBuilder
import org.typelevel.log4cats.Logger
import org.typelevel.log4cats.slf4j.Slf4jLogger

import scala.concurrent.duration.*

object P2PServer:
  def serve[F[_]: Async: Network](
      bindHost: String,
      bindPort: Int,
      handleSocket: (Socket[F], Option[PeerAddress]) => F[Unit],
      outboundConnections: Stream[F, PeerAddress]
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
      network = Network[F]
      inboundSockets = network.server(h.some, p.some, socketOptions)
      inboundHandler = inboundSockets
        .evalTap(socket => socket.remoteAddress.flatTap(address => logger.info(show"Inbound connection from $address")))
        .map(socket => Stream.exec(handleSocket(socket, None)))
        .parJoinUnbounded
      outboundHandler = outboundConnections
        .evalMap(address =>
          OptionT
            .fromOption(
              (Host.fromString(address.host), Port.fromInt(address.port))
                .mapN(SocketAddress[Host])
            )
            .flatTapNone(logger.info(show"Skipping connection to invalid address=$address"))
            .semiflatTap(_ => logger.info(show"Outbound connection to $address"))
            .tupleLeft(address)
            .value
        )
        .unNone
        .map((address, socketAddress) =>
          Stream.exec(
            network
              .client(socketAddress, socketOptions)
              .timeout(5.seconds)
              .use(handleSocket(_, address.some))
          )
        )
        .parJoinUnbounded
      handler = inboundHandler.merge(outboundHandler).compile.drain
      outcome <- handler.void.background
    } yield outcome

  def serveBlockchain[F[_]: Async: Network: Random: CryptoResources](
      core: BlockchainCore[F],
      bindHost: String,
      bindPort: Int,
      publicHost: Option[String],
      publicPort: Option[Int],
      magicBytes: Array[Byte],
      initialPeers: List[PeerAddress]
  ): Resource[F, F[Outcome[F, Throwable, Unit]]] =
    for {
      given Logger[F] <- Slf4jLogger.fromName("P2P").toResource
      _ <- Resource.onFinalize(Logger[F].info("P2P Terminated"))
      outboundConnectionsChannel <- Resource
        .make(Channel.unbounded[F, PeerAddress])(_.close.void)
        .evalTap(channel => initialPeers.traverse(channel.send))
      derivedPublicHost <- publicHost.traverse {
        case "auto" => determinePublicIp[F].toResource
        case h      => h.pure[F].toResource
      }
      localPeer <- LocalPeer
        .make(core, derivedPublicHost, publicPort)
        .evalTap(localPeer => Logger[F].info(show"Local peer id=${localPeer.connectedPeer.peerId}"))
      peersManager <- PeersManager
        .make(core, localPeer, magicBytes, outboundConnectionsChannel.send(_).void, initialPeers)
      outcomeF <- serve(bindHost, bindPort, peersManager.handleSocket, outboundConnectionsChannel.stream)
      _ <- Logger[F]
        .info(
          "Serving P2P on" +
            s" binding=$bindHost:$bindPort" +
            s" public=${localPeer.connectedPeer.host.getOrElse("")}${localPeer.connectedPeer.port.fold("")(":" + _)}"
        )
        .toResource
    } yield outcomeF

  private val socketOptions = List(SocketOption.noDelay(true), SocketOption.keepAlive(true))

  private def determinePublicIp[F[_]: Async: Network: Logger]: F[String] =
    EmberClientBuilder
      .default[F]
      .build
      .use(_.expect[String]("https://checkip.amazonaws.com"))
      // Endpoint might return a comma-delimited list, with the last entry being most "correct"
      .map(_.trim.split(',').last)
      .flatTap(ip => Logger[F].warn(s"IP address auto-detected as address=$ip"))
