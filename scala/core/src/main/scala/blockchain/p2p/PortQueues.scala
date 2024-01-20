package blockchain.p2p

import blockchain.{Bytes, Height}
import blockchain.models.*
import cats.MonadThrow
import cats.data.OptionT
import cats.effect.{Async, Resource, Deferred}
import cats.effect.std.Queue
import cats.implicits.*
import cats.effect.implicits.*
import fs2.Stream

case class PortQueues[F[_], Request, Response](
    requests: Queue[F, Request],
    responses: Queue[F, Deferred[F, Response]]
):
  def processRequest(request: Request): F[Unit] =
    requests.offer(request)
  def processResponse(response: Response)(using MonadThrow[F]): F[Unit] =
    OptionT(responses.tryTake)
      .getOrRaise(new IllegalStateException("Unexpected Response"))
      .flatMap(_.complete(response))
      .void
  def backgroundRequestProcessor(
      subProcessor: Request => F[Unit]
  )(using Async[F]): Stream[F, Unit] =
    Stream
      .fromQueueUnterminated(requests)
      .evalMap(subProcessor)
  def createResponse(using Async[F]): F[Response] =
    Deferred[F, Response].flatTap(responses.offer).flatMap(_.get)

object PortQueues:
  def make[F[_]: Async, Request, Response]: Resource[F, PortQueues[F, Request, Response]] =
    (
      Queue.unbounded[F, Request].toResource,
      Queue
        .unbounded[F, Deferred[F, Response]]
        .toResource
    )
      .mapN(PortQueues.apply)

case class AllPortQueues[F[_]](
    p2pState: PortQueues[F, Unit, PublicP2PState],
    blockAdoptions: PortQueues[F, Unit, BlockId],
    transactionAdoptions: PortQueues[F, Unit, TransactionId],
    pingPong: PortQueues[F, Bytes, Bytes],
    blockIdAtHeight: PortQueues[F, Height, Option[BlockId]],
    headers: PortQueues[F, BlockId, Option[BlockHeader]],
    bodies: PortQueues[F, BlockId, Option[BlockBody]],
    transactions: PortQueues[F, TransactionId, Option[Transaction]]
)

object AllPortQueues:
  def make[F[_]: Async]: Resource[F, AllPortQueues[F]] =
    (
      PortQueues.make[F, Unit, PublicP2PState],
      PortQueues.make[F, Unit, BlockId],
      PortQueues.make[F, Unit, TransactionId],
      PortQueues.make[F, Bytes, Bytes],
      PortQueues.make[F, Height, Option[BlockId]],
      PortQueues.make[F, BlockId, Option[BlockHeader]],
      PortQueues.make[F, BlockId, Option[BlockBody]],
      PortQueues.make[F, TransactionId, Option[Transaction]]
    ).mapN(AllPortQueues.apply[F])

object MultiplexerIds:
  val BlockIdAtHeightRequest = 10
  val HeaderRequest = 11
  val BodyRequest = 12
  val BlockAdoptionRequest = 13
  val TransactionRequest = 14
  val TransactionNotificationRequest = 15
  val PeerStateRequest = 16
  val PingRequest = 17
