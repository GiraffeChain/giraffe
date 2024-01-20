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

  def writer[F[_]: Monad](socket: Socket[F]): (Int, Chunk[Byte]) => F[Unit] =
    (port, data) =>
      socket.write(
        Chunk.array(Ints.toByteArray(port)) ++
          Chunk.array(Ints.toByteArray(data.size)) ++
          data
      )
