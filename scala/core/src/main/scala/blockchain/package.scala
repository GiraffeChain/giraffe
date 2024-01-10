import cats.data.{EitherT, NonEmptyChain}

package object blockchain {
  type ValidationResult[F[_]] = EitherT[F, NonEmptyChain[String], Unit]
}
