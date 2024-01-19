package blockchain.crypto

import blockchain.utility.UnsafeResource
import cats.effect.Resource
import cats.effect.implicits.*
import cats.effect.kernel.Async
import cats.implicits.*

case class CryptoResources[F[_]](
    blake2b256: Resource[F, Blake2b256],
    blake2b512: Resource[F, Blake2b512],
    ed25519VRF: Resource[F, Ed25519VRF],
    kesProduct: Resource[F, KesProduct],
    ed25519: Resource[F, Ed25519]
)

object CryptoResources:

  def apply[F[_]: CryptoResources]: CryptoResources[F] =
    summon[CryptoResources[F]]
  def make[F[_]: Async]: Resource[F, CryptoResources[F]] =
    Async[F]
      .delay(Runtime.getRuntime.availableProcessors())
      .toResource
      .flatMap { parallelism =>
        def c[T](f: => T) =
          UnsafeResource.make(parallelism)(Async[F].delay(f).toResource)
        (
          c(new Blake2b256),
          c(new Blake2b512),
          c(new Ed25519VRF),
          c(new KesProduct),
          c(new Ed25519)
        ).mapN(CryptoResources.apply)
      }
