package blockchain

import blockchain.models.BlockId
import blockchain.codecs.given
import cats.data.{NonEmptyChain, OptionT}
import cats.effect.{Async, Resource, Sync}
import cats.implicits.*

trait BlockIdTree[F[_]]:
  def parentOf(blockId: BlockId): F[Option[BlockId]]
  def associate(child: BlockId, parent: BlockId): F[Unit]
  def heightOf(t: BlockId): F[Long]
  def findCommonAncestor(
      a: BlockId,
      b: BlockId
  ): F[(NonEmptyChain[BlockId], NonEmptyChain[BlockId])]

object BlockIdTree:
  def make[F[_]: Async](
      read: BlockId => F[Option[(Long, BlockId)]],
      write: (BlockId, (Long, BlockId)) => F[Unit],
      genesisParent: BlockId
  ): Resource[F, BlockIdTree[F]] =
    Resource.pure(new BlockIdTreeImpl[F](read, write, genesisParent))

class BlockIdTreeImpl[F[_]: Async](
    read: BlockId => F[Option[(Long, BlockId)]],
    write: (BlockId, (Long, BlockId)) => F[Unit],
    genesisParent: BlockId
) extends BlockIdTree[F]:

  private def readOrRaise(id: BlockId) =
    OptionT(read(id)).getOrElseF(
      Async[F].raiseError(
        new NoSuchElementException(show"Element not found. id=$id")
      )
    )

  def parentOf(t: BlockId): F[Option[BlockId]] =
    if (t == genesisParent) none[BlockId].pure[F]
    else OptionT(read(t)).map(_._2).value

  def associate(child: BlockId, parent: BlockId): F[Unit] =
    if (parent == genesisParent) write(child, (1, parent))
    else
      readOrRaise(parent).flatMap { case (height, _) =>
        write(child, (height + 1, parent))
      }

  def heightOf(t: BlockId): F[Long] =
    if (t == genesisParent) 0L.pure[F]
    else readOrRaise(t).map(_._1)

  def findCommonAncestor(
      a: BlockId,
      b: BlockId
  ): F[(NonEmptyChain[BlockId], NonEmptyChain[BlockId])] =
    if (a == b) (NonEmptyChain(a), NonEmptyChain(b)).pure[F]
    else
      for {
        (aHeight, bHeight) <- (heightOf(a), heightOf(b)).tupled
        (aAtEqualHeight, bAtEqualHeight) <-
          if (aHeight === bHeight) (NonEmptyChain(a), NonEmptyChain(b)).pure[F]
          else if (aHeight < bHeight)
            traverseBackToHeight(NonEmptyChain(b), bHeight, aHeight).map(
              NonEmptyChain(a) -> _._1
            )
          else
            traverseBackToHeight(NonEmptyChain(a), aHeight, bHeight).map(
              _._1 -> NonEmptyChain(b)
            )
        (chainA, chainB) <- (aAtEqualHeight, bAtEqualHeight).iterateUntilM {
          case (aChain, bChain) =>
            (prependWithParent(aChain), prependWithParent(bChain)).tupled
        } { case (aChain, bChain) => aChain.head == bChain.head }
      } yield (chainA, chainB)

  private def traverseBackToHeight(
      collection: NonEmptyChain[BlockId],
      initialHeight: Long,
      targetHeight: Long
  ): F[(NonEmptyChain[BlockId], Long)] =
    Sync[F].defer(
      (collection, initialHeight)
        .iterateUntilM { case (chain, height) =>
          prependWithParent(chain).map(_ -> (height - 1))
        }(_._2 === targetHeight)
    )

  private def prependWithParent(
      c: NonEmptyChain[BlockId]
  ): F[NonEmptyChain[BlockId]] =
    readOrRaise(c.head).map(_._2).map(c.prepend)
