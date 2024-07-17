package blockchain.p2p

import blockchain.models.*
import blockchain.{Bytes, Height}
import cats.data.OptionT
import cats.effect.implicits.*
import cats.effect.std.{Mutex, Queue}
import cats.effect.{Async, Deferred, Resource}
import cats.implicits.*
import cats.{Monad, MonadThrow}
import com.google.common.primitives.Ints
import com.google.protobuf.ByteString
import fs2.io.net.Socket
import fs2.{Chunk, Stream, *}

import scala.concurrent.duration.*

object MultiplexedFraming:
  def apply[F[_]: Monad](socket: Socket[F]): Stream[F, (Int, Chunk[Byte])] =
    Stream
      .repeatEval(
        OptionT(socket.read(8))
          .map(prefix =>
            (
              Ints.fromBytes(prefix(0), prefix(1), prefix(2), prefix(3)),
              Ints.fromBytes(prefix(4), prefix(5), prefix(6), prefix(7))
            )
          )
          .flatMap((port, length) =>
            if (length == 0) OptionT.some[F]((port, Chunk.empty[Byte]))
            else OptionT(socket.read(length)).tupleLeft(port)
          )
          .value
      )
      .unNoneTerminate

  def writer[F[_]: Async](socket: Socket[F]): (Int, Chunk[Byte]) => F[Unit] =
    (port, data) =>
      socket
        .write(
          Chunk.array(Ints.toByteArray(port)) ++
            Chunk.array(Ints.toByteArray(data.size)) ++
            data
        )
        .timeout(3.seconds)

case class MultiplexedReaderWriter[F[_]](
    read: Stream[F, (Int, Bytes)],
    write: (Int, Bytes) => F[Unit]
)

object MultiplexedReaderWriter:
  def forSocket[F[_]: Async](socket: Socket[F]): Resource[F, MultiplexedReaderWriter[F]] = {
    val writer = MultiplexedFraming.writer(socket)
    Mutex[F].toResource.map(mutex =>
      MultiplexedReaderWriter[F](
        MultiplexedFraming(socket).buffer(1).map((port, chunk) => (port, ByteString.copyFrom(chunk.toByteBuffer))),
        (port, data) => mutex.lock.surround(writer.apply(port, Chunk.byteBuffer(data.asReadOnlyByteBuffer())))
      )
    )
  }

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
