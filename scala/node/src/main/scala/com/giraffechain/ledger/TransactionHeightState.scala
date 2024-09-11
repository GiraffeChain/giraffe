package com.giraffechain.ledger

import cats.effect.{Async, MonadCancelThrow, Resource}
import cats.implicits.*
import com.giraffechain.*
import com.giraffechain.models.*

trait TransactionHeightState[F[_]]:
  def transactionHeight(blockId: BlockId)(id: TransactionId): F[Option[Height]]

object TransactionHeightState:
  type State[F[_]] = Store[F, TransactionId, Height]
  type BSS[F[_]] = BlockSourcedState[F, State[F]]

  def make[F[_]: MonadCancelThrow](bss: BSS[F]): Resource[F, TransactionHeightState[F]] =
    Resource.pure(new TransactionHeightStateImpl[F](bss))

  def makeBSS[F[_]: Async](
      initialState: F[State[F]],
      initialBlockId: F[BlockId],
      blockIdTree: BlockIdTree[F],
      onBlockChanged: BlockId => F[Unit],
      fetchHeader: FetchHeader[F],
      fetchBody: FetchBody[F]
  ): Resource[F, BSS[F]] =
    new TransactionHeightStateBSSImpl[F](fetchHeader, fetchBody).makeBss(
      initialState,
      initialBlockId,
      blockIdTree,
      onBlockChanged
    )

class TransactionHeightStateImpl[F[_]: MonadCancelThrow](bss: TransactionHeightState.BSS[F])
    extends TransactionHeightState[F]:
  override def transactionHeight(blockId: BlockId)(id: TransactionId): F[Option[Height]] =
    bss.stateAt(blockId).use(_.get(id))

class TransactionHeightStateBSSImpl[F[_]: Async](
    fetchHeader: FetchHeader[F],
    fetchBody: FetchBody[F]
):
  def makeBss(
      initialState: F[TransactionHeightState.State[F]],
      initialBlockId: F[BlockId],
      blockIdTree: BlockIdTree[F],
      onBlockChanged: BlockId => F[Unit]
  ): Resource[F, TransactionHeightState.BSS[F]] =
    BlockSourcedState.make[F, TransactionHeightState.State[F]](
      initialState,
      initialBlockId,
      applyBlock,
      unapplyBlock,
      blockIdTree,
      onBlockChanged
    )

  def applyBlock(state: TransactionHeightState.State[F], blockId: BlockId): F[TransactionHeightState.State[F]] =
    (fetchHeader(blockId), fetchBody(blockId)).tupled
      .flatMap((header, body) => body.transactionIds.traverse(id => state.put(id, header.height)))
      .as(state)

  def unapplyBlock(
      state: TransactionHeightState.State[F],
      blockId: BlockId
  ): F[TransactionHeightState.State[F]] =
    fetchBody(blockId)
      .flatMap(_.transactionIds.traverse(state.remove))
      .as(state)
