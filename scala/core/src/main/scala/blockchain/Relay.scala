package blockchain

import cats.effect.{ExitCode, IO, IOApp}

object Relay extends IOApp:
  type F[A] = IO[A]
  override def run(args: List[String]): IO[ExitCode] =
    ???
  
  private def resource(args: List[String]) =
    for {
      core <- BlockchainCore.make[F]
      
    } yield ()
