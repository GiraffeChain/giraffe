package blockchain.p2p

import blockchain.Bytes
import cats.implicits.*
import cats.Monad
import com.google.protobuf.ByteString
import fs2.*
import fs2.io.net.Socket

case class MultiplexedReaderWriter[F[_]](
    read: Stream[F, (Int, Bytes)],
    write: (Int, Bytes) => F[Unit]
)

object MultiplexedReaderWriter:
  def forSocket[F[_]: Monad](socket: Socket[F]): MultiplexedReaderWriter[F] = {
    val writer = MultiplexedFraming.writer(socket)
    MultiplexedReaderWriter[F](
      MultiplexedFraming(socket).buffer(1).map((port, chunk) => (port, ByteString.copyFrom(chunk.toByteBuffer))),
      (port, data) => writer.apply(port, Chunk.byteBuffer(data.asReadOnlyByteBuffer()))
    )
  }
