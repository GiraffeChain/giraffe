package blockchain

import blockchain.crypto.CryptoResources
import blockchain.p2p.P2PServer
import blockchain.rpc.BlockchainRpc
import blockchain.codecs.given
import cats.effect.std.{Random, SecureRandom}
import cats.effect.{ExitCode, IO, IOApp, Resource}
import cats.implicits.*
import fs2.io.file.{Files, Path}
import caseapp.*
import cats.MonadThrow
import com.comcast.ip4s.SocketAddress
import org.typelevel.log4cats.slf4j.Slf4jLogger

object Relay extends IOApp:
  type F[A] = IO[A]
  override def run(args: List[String]): IO[ExitCode] =
    resource(args).useForever

  private def resource(args: List[String]): Resource[F, ExitCode] =
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
      genesis <- Testnet.init[F](Path("/tmp/blockchain-genesis"), args.testnet.getOrElse("")).toResource
      _ <- logger.info(show"Genesis id=${genesis.header.id} timestamp=${genesis.header.timestamp}").toResource
      dataDir = Path(show"${args.dataDir}/${genesis.header.id}")
      _ <- logger.info(show"Data dir=$dataDir").toResource
      core <- BlockchainCore.make[F](genesis, dataDir)
      _ <- BlockchainRpc.serve(core, args.rpcBindHost, args.rpcBindPort)
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
    } yield ExitCode.Success

@AppName("Blockchain")
case class RelayArgs(
    @HelpMessage("Path to data storage (will be suffixed with the block ID)")
    dataDir: String = "/tmp/blockchain/data",
    rpcBindHost: String = "0.0.0.0",
    rpcBindPort: Int = 2024,
    p2pBindHost: String = "0.0.0.0",
    p2pBindPort: Int = 2023,
    p2pPublicHost: Option[String] = Some("localhost"),
    p2pPublicPort: Option[Int] = Some(2023),
    peer: List[String] = Nil,
    testnet: Option[String] = None
):
  def parsedPeers[F[_]: MonadThrow]: F[List[SocketAddress[?]]] =
    peer.traverse(p =>
      SocketAddress.fromString(p).toRight(new IllegalArgumentException(s"Invalid peer=$p")).pure[F].rethrow
    )
