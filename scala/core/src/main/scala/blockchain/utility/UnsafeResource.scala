package blockchain.utility

import cats.effect.implicits.*
import cats.effect.kernel.Async
import cats.effect.std.Queue
import cats.effect.*
import cats.implicits.*

object UnsafeResource:
  def make[F[_]: Async, T](parallelism: Int)(
      base: Resource[F, T]
  ): Resource[F, Resource[F, T]] =
    for {
      queue <- Queue.unbounded[F, T].toResource
      allocations <- base.allocated.replicateA(parallelism).toResource
      _ <- Resource.onFinalize(allocations.traverse(a => a._2).void)
      _ <- allocations.traverse(a => queue.offer(a._1)).toResource
      res = Resource.make(Sync[F].defer(queue.take))(t => Sync[F].defer(queue.offer(t)))
    } yield res
