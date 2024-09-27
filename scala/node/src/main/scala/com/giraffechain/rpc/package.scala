package com.giraffechain

import cats.data.{EitherT, NonEmptyChain}
import cats.effect.Async
import cats.implicits.*
import cats.{ApplicativeThrow, MonadThrow}
import com.giraffechain.codecs.given
import com.giraffechain.ledger.TransactionValidationContext
import com.giraffechain.models.*
import fs2.{RaiseThrowable, Stream}
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

  extension [F[_], A](io: F[A])
    def logError(using MonadThrow[F])(using Logger[F]): F[A] =
      io.onError(e => Logger[F].warn(e)("Request error"))

  extension [F[_], A](stream: Stream[F, A])
    def logError(using RaiseThrowable[F])(using Logger[F]): Stream[F, A] =
      stream.handleErrorWith(e => Stream.exec(Logger[F].warn(e)("Stream error")) ++ Stream.raiseError(e))

  def broadcastBlockImpl[F[_]: Async: Logger](
      core: BlockchainCore[F]
  )(block: Block, reward: Option[Transaction]): ValidationResult[F] =
    for {
      header <- EitherT.rightT(block.header.withEmbeddedId)
      rewardTransaction = reward.map(_.withEmbeddedId)
      rewardTransactionId = rewardTransaction.map(_.id)
      _ <- EitherT.liftF(Logger[F].info(show"Received block id=${header.id}"))
      canonicalHeadId <- EitherT.liftF(core.consensus.localChain.currentHead)
      _ <- EitherT.cond(header.parentHeaderId == canonicalHeadId, (), NonEmptyChain("Block does not extend local tip"))
      _ <- core.consensus.headerValidation.validate(header)
      _ <- EitherT.liftF(
        core.blockIdTree.associate(header.id, header.parentHeaderId) *>
          core.dataStores.headers.put(header.id, header) *>
          core.dataStores.bodies.put(header.id, block.body) *>
          rewardTransaction.traverse(t => core.dataStores.transactions.put(t.id, t))
      )
      transactions <- EitherT.liftF(
        block.body.transactionIds.traverse(id =>
          if (rewardTransactionId.contains(id)) rewardTransaction.get.pure[F]
          else core.dataStores.transactions.getOrRaise(id)
        )
      )
      _ <- core.ledger.bodyValidation
        .validate(
          FullBlockBody(transactions),
          TransactionValidationContext(header.parentHeaderId, header.height, header.slot)
        )
      // Duplicate check, right before adoption
      _ <- EitherT.cond(header.parentHeaderId == canonicalHeadId, (), NonEmptyChain("Block does not extend local tip"))
      _ <- EitherT.liftF(core.consensus.localChain.adopt(header.id))
    } yield ()
