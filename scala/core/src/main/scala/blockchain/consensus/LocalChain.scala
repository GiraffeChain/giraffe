package blockchain.consensus

import blockchain.BlockSourcedState
import blockchain.models.*
import blockchain.codecs.given
import blockchain.utility.given
import cats.data.EitherT
import cats.effect.{Async, Ref, Resource}
import cats.implicits.*
import cats.effect.implicits.*
import fs2.concurrent.Topic
import org.typelevel.log4cats.Logger
import org.typelevel.log4cats.slf4j.{Slf4jFactory, given}

trait LocalChain[F[_]]:
  def adopt(blockId: BlockId): F[Unit]
  def currentHead: F[BlockId]
  def genesis: F[BlockId]
  def adoptions: fs2.Stream[F, BlockId]
  def blockIdAtHeight(height: Long): F[Option[BlockId]]

object LocalChain:
  def make[F[_]: Async](
      genesisId: BlockId,
      blockHeightsBSS: BlockHeights.BSS[F],
      initialHead: BlockId
  ): Resource[F, LocalChain[F]] =
    (
      Resource.make(Topic[F, BlockId])(_.close.void),
      Ref.of(initialHead).toResource
    )
      .mapN((topic, ref) =>
        new LocalChainImpl[F](genesisId, blockHeightsBSS, topic, ref)
      )

class LocalChainImpl[F[_]: Async](
    genesisId: BlockId,
    blockHeightsBSS: BlockHeights.BSS[F],
    adoptionsTopic: Topic[F, BlockId],
    headRef: Ref[F, BlockId]
) extends LocalChain[F]:

  private given Logger[F] =
    Slf4jFactory.getLoggerFromName[F]("Blockchain.Consensus.LocalChain")
  override def adopt(blockId: BlockId): F[Unit] =
    Async[F].uncancelable(_ =>
      headRef.set(blockId) *>
        EitherT(adoptionsTopic.publish1(blockId))
          .leftMap(_ =>
            new IllegalStateException("LocalChain topic unexpectedly closed")
          )
          .rethrowT *>
        Logger[F].info(show"Adopted head block id=$blockId")
    )

  override def currentHead: F[BlockId] = headRef.get

  override def genesis: F[BlockId] = genesisId.pure[F]

  override def adoptions: fs2.Stream[F, BlockId] =
    adoptionsTopic.subscribe(Int.MaxValue)

  override def blockIdAtHeight(height: Long): F[Option[BlockId]] =
    currentHead.flatMap(blockHeightsBSS.useStateAt(_)(_.apply(height)))
