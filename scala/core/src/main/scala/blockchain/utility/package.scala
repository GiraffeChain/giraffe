package blockchain

import cats.effect.{Resource, Sync}

package object utility:
  extension [F[_]: Sync, T](resource: Resource[F, T])
    def useSync[O](f: T => O): F[O] =
      resource.use(v => Sync[F].delay(f(v)))
