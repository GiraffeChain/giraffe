package blockchain

import cats.effect.Temporal
import cats.effect.implicits.*
import cats.implicits.*

import scala.concurrent.TimeoutException
import scala.concurrent.duration.*

package object p2p {
  val DefaultLocalOperationTimeout: FiniteDuration = 2.seconds
  val DefaultReadTimeout: FiniteDuration = 5.seconds
  val DefaultWriteTimeout: FiniteDuration = 5.seconds

  extension [F[_]: Temporal, A](fa: F[A])
    def timeoutWithMessage(duration: FiniteDuration, message: => String): F[A] =
      fa.timeout(duration).adaptError { case _: TimeoutException => new TimeoutException(message) }

}
