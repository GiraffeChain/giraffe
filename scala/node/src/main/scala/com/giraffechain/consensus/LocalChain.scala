package com.giraffechain.consensus

import cats.data.EitherT
import cats.effect.implicits.*
import cats.effect.{Async, Ref, Resource}
import cats.implicits.*
import com.giraffechain.models.*
import com.giraffechain.{FetchHeader, Genesis}
import fs2.concurrent.Topic

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
      initialHead: BlockId,
      fetchHeader: FetchHeader[F]
  ): Resource[F, LocalChain[F]] =
    (
      Resource.make(Topic[F, BlockId])(_.close.void),
      Ref.of(initialHead).toResource
    )
      .mapN((topic, ref) => new LocalChainImpl[F](genesisId, blockHeightsBSS, topic, ref, fetchHeader))

class LocalChainImpl[F[_]: Async](
    genesisId: BlockId,
    blockHeightsBSS: BlockHeights.BSS[F],
    adoptionsTopic: Topic[F, BlockId],
    headRef: Ref[F, BlockId],
    fetchHeader: FetchHeader[F]
) extends LocalChain[F]:

  override def adopt(blockId: BlockId): F[Unit] =
    Async[F].uncancelable(_ =>
      headRef.set(blockId) *>
        EitherT(adoptionsTopic.publish1(blockId))
          .leftMap(_ => new IllegalStateException("LocalChain topic unexpectedly closed"))
          .rethrowT
    )

  override def currentHead: F[BlockId] = headRef.get

  override def genesis: F[BlockId] = genesisId.pure[F]

  override def adoptions: fs2.Stream[F, BlockId] =
    adoptionsTopic.subscribe(Int.MaxValue)

  override def blockIdAtHeight(height: Long): F[Option[BlockId]] =
    if (height == Genesis.Height)
      genesis.map(_.some)
    else if (height > Genesis.Height)
      currentHead.flatMap(blockHeightsBSS.stateAt(_).use(_.apply(height)))
    else if (height == 0L)
      currentHead.map(_.some)
    else
      currentHead
        .flatMap(fetchHeader)
        .map(_.height + height)
        .flatMap(targetHeight =>
          if (targetHeight < Genesis.Height) none[BlockId].pure[F]
          else blockIdAtHeight(targetHeight)
        )
