package com.giraffechain.p2p

import cats.MonadThrow
import cats.data.OptionT
import cats.effect.implicits.*
import cats.effect.std.{Mutex, Queue}
import cats.effect.{Async, Deferred, Resource}
import cats.implicits.*
import com.giraffechain.models.*
import com.giraffechain.{Bytes, Height}
import com.google.common.primitives.Ints
import com.google.protobuf.ByteString
import fs2.io.net.Socket
import fs2.{Chunk, Stream, *}

object MultiplexedFraming:
  def apply[F[_]: Async](socket: Socket[F]): Stream[F, (Int, Chunk[Byte])] = {
    def readPrefix(s: Stream[F, Byte]): Pull[F, (Int, Chunk[Byte]), Unit] =
      s.pull
        .unconsN(8)
        .flatMap {
          case Some((prefix, tail)) =>
            val port = Ints.fromBytes(prefix(0), prefix(1), prefix(2), prefix(3))
            val length = Ints.fromBytes(prefix(4), prefix(5), prefix(6), prefix(7))
            readData(tail)(port, length)
          case _ =>
            Pull.done
        }
    def readData(s: Stream[F, Byte])(port: Int, length: Int): Pull[F, (Int, Chunk[Byte]), Unit] =
      s.pull
        .unconsN(length)
        .flatMap {
          case Some((data, tail)) =>
            Pull.output1((port, data)) >> readPrefix(tail)
          case _ =>
            Pull.raiseError(new IllegalArgumentException(s"Expected $length bytes."))
        }
    readPrefix(socket.reads).stream
  }

  def writer[F[_]: Async](socket: Socket[F]): (Int, Chunk[Byte]) => F[Unit] =
    (port, data) =>
      Async[F]
        .delay(
          Chunk.array(Ints.toByteArray(port)) ++
            Chunk.array(Ints.toByteArray(data.size)) ++
            data
        )
        .flatMap(socket.write)
        .timeoutWithMessage(DefaultWriteTimeout, s"Write timeout in port=$port")

case class MultiplexedReaderWriter[F[_]](
    read: Stream[F, (Int, Bytes)],
    write: (Int, Bytes) => F[Unit]
)

object MultiplexedReaderWriter:
  def forSocket[F[_]: Async](socket: Socket[F]): Resource[F, MultiplexedReaderWriter[F]] =
    Resource.pure(
      MultiplexedReaderWriter[F](
        MultiplexedFraming(socket).map((port, chunk) => (port, ByteString.copyFrom(chunk.toByteBuffer))),
        (port, data) => MultiplexedFraming.writer[F](socket).apply(port, Chunk.byteBuffer(data.asReadOnlyByteBuffer()))
      )
    )

case class PortQueues[F[_], Request, Response](
    requests: Queue[F, Request],
    responses: Queue[F, Deferred[F, Response]],
    mutex: Mutex[F]
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
  def expectResponse(innerEffect: F[Unit])(using Async[F]): F[Response] =
    mutex.lock.surround(Deferred[F, Response].flatTap(responses.offer).map(_.get) <& innerEffect).flatten

object PortQueues:
  def make[F[_]: Async, Request, Response]: Resource[F, PortQueues[F, Request, Response]] =
    (
      Queue.unbounded[F, Request].toResource,
      Queue.unbounded[F, Deferred[F, Response]].toResource,
      Mutex[F].toResource
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
