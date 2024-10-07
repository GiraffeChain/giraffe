package com.giraffechain.utility

import cats.effect.Async
import cats.implicits.*
import com.giraffechain.codecs.given
import com.giraffechain.ledger.HeaderToBodyValidation
import com.giraffechain.models.*
import fs2.io.file.{Files, Path}
import fs2.{Chunk, Stream}

object BlockLoading:
  def save[F[_]: Async: Files](dir: Path)(block: FullBlock): F[Unit] =
    for {
      _ <- Files[F].createDirectories(dir)
      idStr = block.header.id.show
      _ <- Stream.chunk(Chunk.array(block.toByteArray)).through(Files[F].writeAll(dir / s"$idStr.pbuf")).compile.drain
      // TODO: JSON?
    } yield ()

  /** Loads the given FullBlock by its ID using the supplied file reader function.
    * @param readFile
    *   A function which retrieves a file
    * @param blockId
    *   The block ID to retrieve
    * @return
    *   a FullBlock associated with the given block ID
    */
  def load[F[_]: Async](
      readFile: F[Array[Byte]]
  )(txRootValidation: HeaderToBodyValidation[F])(blockId: BlockId): F[FullBlock] =
    readFile
      .map(FullBlock.parseFrom)
      .map(b => b.copy(header = b.header.withEmbeddedId))
      .ensure(new IllegalArgumentException("Computed header ID is not the same as requested header ID"))(
        _.header.id == blockId
      )
      .map(_.update(_.fullBody.update(_.transactions.foreach(_.modify(_.withEmbeddedId)))))
      .flatTap(fullBlock => 
        Async[F].delay(Block(fullBlock.header, BlockBody(fullBlock.fullBody.transactions.map(_.id))))
          .flatMap(txRootValidation.validate(_).leftMap(errors => new IllegalArgumentException(errors.toString)).rethrowT)
      )
