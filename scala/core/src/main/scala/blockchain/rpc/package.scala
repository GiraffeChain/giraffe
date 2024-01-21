package blockchain

import cats.ApplicativeThrow
import cats.implicits.*
import io.grpc.{Status, StatusException}
import org.typelevel.log4cats.Logger
import scalapb.validate.*

package object rpc:
  extension (throwable: Throwable)
    def asGrpcException: StatusException =
      throwable match {
        case e: StatusException => e
        case i: IllegalArgumentException =>
          Status.INVALID_ARGUMENT.withDescription(i.getMessage).asException()
        case f: FieldValidationException =>
          Status.INVALID_ARGUMENT.withDescription(f.getMessage).asException()
        case e: NotImplementedError =>
          Status.UNIMPLEMENTED.withDescription(e.getMessage).asException()
        case e =>
          Status.fromThrowable(e).asException()
      }

  extension [F[_], A](fa: F[A])
    def adaptErrorsToGrpc(using ApplicativeThrow[F]): F[A] = fa.adaptErr { case e => e.asGrpcException }
    def warnLogErrors(using Logger[F])(using ApplicativeThrow[F]): F[A] = fa.onError { case e =>
      Logger[F].warn(e)("gRPC Error")
    }
