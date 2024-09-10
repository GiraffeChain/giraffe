package com.giraffechain

import com.giraffechain.codecs.given
import com.giraffechain.crypto.CryptoResources
import com.giraffechain.p2p.P2PServer
import com.giraffechain.rpc.*
import caseapp.*
import cats.MonadThrow
import cats.effect.std.{Random, SecureRandom}
import cats.effect.{IO, Resource, ResourceApp}
import cats.implicits.*
import com.comcast.ip4s.SocketAddress
import fs2.io.file.{Files, Path}
import org.typelevel.log4cats.LoggerFactory
import org.typelevel.log4cats.slf4j.{Slf4jFactory, Slf4jLogger}

object NodeMain extends ResourceApp.Forever:

  private given LoggerFactory[IO] = Slf4jFactory.create[IO]

  type F[A] = IO[A]

  override def run(args: List[String]): Resource[F, Unit] =
    for {
      given CryptoResources[F] <- CryptoResources.make[F]
      given Files[F] = Files.forIO
      given Random[F] <- SecureRandom.javaSecuritySecureRandom[F].toResource
      logger <- Slf4jLogger.fromName[F]("Relay").toResource
      (args, _) <- CaseApp
        .parse[RelayArgs](args)
        .leftMap(e => new IllegalArgumentException(e.message))
        .pure[F]
        .rethrow
        .toResource
      genesis <- Genesis.parse[F](args.genesis).toResource
      _ <- logger.info(show"Genesis id=${genesis.header.id} timestamp=${genesis.header.timestamp}").toResource
      dataDir = Path(show"${args.dataDir}/${genesis.header.id}")
      _ <- logger.info(show"Data dir=$dataDir").toResource
      core <- BlockchainCore.make[F](genesis, dataDir)
      _ <- new JsonBlockchainRpc(core).serve(args.apiBindHost, args.apiBindPort)
      given Random[F] <- SecureRandom.javaSecuritySecureRandom[F].toResource
      magicBytes = Array.fill(32)(0: Byte)
      parsedPeers <- args.parsedPeers[F].toResource
      p2pOutcome <- P2PServer.serveBlockchain(
        core,
        args.p2pBindHost,
        args.p2pBindPort,
        args.p2pPublicHost,
        args.p2pPublicPort,
        magicBytes,
        parsedPeers
      )
      r <- p2pOutcome.toResource
      _ <- r.embedError.toResource
    } yield ()

@AppName("Blockchain")
case class RelayArgs(
    @HelpMessage("Path to data storage (will be suffixed with the block ID)")
    dataDir: String = Option(System.getenv("BLOCKCHAIN_DATA_DIR")).getOrElse("/tmp/blockchain/data"),
    apiBindHost: String = "0.0.0.0",
    apiBindPort: Int = 2024,
    p2pBindHost: String = "0.0.0.0",
    p2pBindPort: Int = 2023,
    p2pPublicHost: Option[String] = None,
    p2pPublicPort: Option[Int] = Some(2023),
    peer: List[String] = Nil,
    genesis: String = "testnet:"
):
  def parsedPeers[F[_]: MonadThrow]: F[List[SocketAddress[?]]] =
    peer.traverse(p =>
      SocketAddress.fromString(p).toRight(new IllegalArgumentException(s"Invalid peer=$p")).pure[F].rethrow
    )
