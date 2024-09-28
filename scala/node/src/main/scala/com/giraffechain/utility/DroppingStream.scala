package com.giraffechain.utility
import cats.effect.Async
import cats.effect.std.Queue
import fs2.Stream

object DroppingStream {
  def apply[F[_]: Async, A](s: Stream[F, A], buffer: Int = 1): Stream[F, A] =
    Stream
      .eval(Queue.circularBuffer[F, Option[A]](buffer))
      .flatMap(queue => Stream.fromQueueNoneTerminated(queue).concurrently(s.enqueueNoneTerminated(queue)))
}
