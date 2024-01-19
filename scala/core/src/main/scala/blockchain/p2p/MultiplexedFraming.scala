package blockchain.p2p

import cats.Monad
import cats.implicits.*
import cats.data.OptionT
import com.google.common.primitives.Ints
import fs2.io.net.Socket
import fs2.{Chunk, Stream}

object MultiplexedFraming:
  def apply[F[_]: Monad](socket: Socket[F]): Stream[F, (Int, Chunk[Byte])] =
    Stream
      .repeatEval(
        OptionT(socket.read(8))
          .map(chunk => chunk.splitAt(4))
          .map((portBytes, lengthBytes) =>
            (
              Ints.fromByteArray(portBytes.toArray),
              Ints.fromByteArray(lengthBytes.toArray)
            )
          )
          .flatMap((port, length) =>
            OptionT(socket.read(length)).tupleLeft(port)
          )
          .value
      )
      .unNoneTerminate

  def writer[F[_]: Monad](socket: Socket[F]): (Int, Chunk[Byte]) => F[Unit] =
    (port, data) =>
      socket.write(
        Chunk.array(Ints.toByteArray(port)) ++
          Chunk.array(Ints.toByteArray(data.size))
      ) >> socket.write(data)
