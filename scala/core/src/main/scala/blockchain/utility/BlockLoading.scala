package blockchain.utility

import blockchain.codecs.given
import blockchain.ledger.HeaderToBodyValidation
import blockchain.models.{Block, BlockBody, BlockHeader, BlockId, FullBlock, FullBlockBody, Transaction, TransactionId}
import cats.implicits.*
import cats.data.{EitherT, ReaderT}
import cats.effect.Async
import fs2.io.file.{Files, Path}
import fs2.{Chunk, Stream}

object BlockLoading:
  def save[F[_]: Async: Files](dir: Path)(block: FullBlock): F[Unit] =
    for {
      _ <- Files[F].createDirectories(dir)
      idStr = block.header.id.show
      writePbuf = (prefix: String, suffix: String, data: Array[Byte]) =>
        Stream.chunk(Chunk.array(data)).through(Files[F].writeAll(dir / s"$prefix.$suffix.pbuf")).compile.drain
      _ <- writePbuf(idStr, "header", block.header.toByteArray)
      body = BlockBody(block.fullBody.transactions.map(_.id))
      _ <- writePbuf(idStr, "body", body.toByteArray)
      _ <- block.fullBody.transactions.traverse(tx => writePbuf(tx.id.show, "transaction", tx.toByteArray))
    } yield ()

  /** Loads the given FullBlock by its ID using the supplied file reader function. The header will be retrieved first,
    * using the file name ${block ID}.header.pbuf. Next, the body will be retrieved using the file name ${block
    * ID}.body.pbuf. Next, all transactions will be retrieved using the file names ${transaction ID}.transaction.pbuf.
    * @param readFile
    *   A function which retrieves a file by name
    * @param blockId
    *   The block ID to retrieve
    * @return
    *   a FullBlock associated with the given block ID
    */
  def load[F[_]: Async](
      readFile: ReaderT[F, String, Array[Byte]]
  )(txRootValidation: HeaderToBodyValidation[F])(blockId: BlockId): F[FullBlock] =
    (
      for {
        genesisBlockIdStr <- EitherT.liftF(Async[F].delay(blockId.show))
        header <-
          EitherT
            .liftF(
              readFile(s"$genesisBlockIdStr.header.pbuf")
                .map(BlockHeader.parseFrom)
            )
            .map(_.withEmbeddedId)
            .ensure("Computed header ID is not the same as requested header ID")(_.id == blockId)
        body <-
          EitherT.liftF(
            readFile(s"$genesisBlockIdStr.body.pbuf")
              .map(BlockBody.parseFrom)
          )
        _ <- txRootValidation
          .validate(Block(header, body))
          .leftMap(_.toString)
        fetchTransaction = (id: TransactionId) =>
          EitherT
            .liftF(
              readFile(s"${id.show}.transaction.pbuf")
                .map(Transaction.parseFrom)
            )
            .map(_.withEmbeddedId)
            .ensure("Computed transaction ID is not the same as requested transaction ID")(_.id == id)
        transactions <- body.transactionIds.parTraverse(fetchTransaction)
        fullBlockBody = FullBlockBody(transactions)
        fullBlock = FullBlock(header, fullBlockBody)
      } yield fullBlock
    ).leftMap(new IllegalArgumentException(_)).rethrowT
