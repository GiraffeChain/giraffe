package com.giraffechain

import cats.*
import cats.data.OptionT
import cats.effect.*
import cats.effect.implicits.*
import cats.implicits.*
import com.giraffechain.utility.Ratio

import scala.concurrent.TimeoutException
import scala.concurrent.duration.*

package object p2p {
  val DefaultLocalOperationTimeout: FiniteDuration = 2.seconds
  val DefaultReadTimeout: FiniteDuration = 5.seconds
  val DefaultWriteTimeout: FiniteDuration = 5.seconds

  extension [F[_]: Temporal, A](fa: F[A])
    def timeoutWithMessage(duration: FiniteDuration, message: => String): F[A] =
      fa.timeout(duration).adaptError { case _: TimeoutException => new TimeoutException(message) }

  extension [F[_]: Temporal, A](fa: F[A])
    def localTimeout(name: String): F[A] =
      fa.timeoutWithMessage(DefaultLocalOperationTimeout, s"Local operation '$name' timeout'")

  def quickSearch[F[_]: Async, T](
      getLocal: Long => F[T],
      getRemote: Long => F[Option[T]],
      count: Long,
      max: Long
  ): F[Option[T]] =
    if (count <= 0 || max <= 0) none.pure[F]
    else
      (getLocal(max), getRemote(max)).parTupled.flatMap((localValue, remoteValue) =>
        if (remoteValue.contains(localValue)) remoteValue.pure[F]
        else quickSearch(getLocal, getRemote, count - 1, max - 1)
      )

  def narySearch[F[_]: MonadThrow, T](
      getLocal: Long => F[T],
      getRemote: Long => F[Option[T]],
      searchSpaceTarget: Ratio
  )(min: Long, max: Long): F[Option[T]] = {
    def f(min: Long, max: Long, ifNone: Option[T]): F[Option[T]] =
      (min === max)
        .pure[F]
        .ifM(
          ifTrue = getLocal(min)
            .flatMap(localValue =>
              OptionT(getRemote(min))
                .filter(_ == localValue)
                .orElse(OptionT.fromOption[F](ifNone))
                .value
            ),
          ifFalse = for {
            targetHeight <-
              (min + ((max - min) * searchSpaceTarget.toDouble).floor.round)
                .pure[F]
            localValue <- getLocal(targetHeight)
            remoteValue <- getRemote(targetHeight)
            result <- remoteValue
              .filter(_ == localValue)
              .fold(f(min, targetHeight, ifNone))(remoteValue => f(targetHeight + 1, max, remoteValue.some))
          } yield result
        )
    f(min, max, None)
  }
}
