package blockchain.ledger

import blockchain.*
import blockchain.models.*
import blockchain.utility.given
import blockchain.codecs.given
import cats.{Functor, MonadThrow}
import cats.data.OptionT
import cats.effect.{Async, Resource, Sync}
import cats.implicits.*

trait TransactionOutputState[F[_]] {

  def transactionOutputIsSpendable(
      blockId: BlockId,
      outputReference: TransactionOutputReference
  ): F[Boolean]

}

object TransactionOutputState:
  type State[F[_]] = Store[F, TransactionId, List[Boolean]]
  type BSS[F[_]] = BlockSourcedState[F, State[F]]

  def makeBSS[F[_]: Async](
      initialState: State[F],
      initialBlockId: BlockId,
      fetchBody: FetchBody[F],
      fetchTransaction: FetchTransaction[F],
      blockIdTree: BlockIdTree[F],
      onBlockChanged: BlockId => F[Unit]
  ): Resource[F, BSS[F]] =
    new TransactionOutputStateBSSImpl[F](fetchBody, fetchTransaction).makeBss(
      initialState,
      initialBlockId,
      blockIdTree,
      onBlockChanged
    )

class TransactionOutputStateImpl[F[_]: Functor](
    bss: TransactionOutputState.BSS[F]
) extends TransactionOutputState[F]:
  override def transactionOutputIsSpendable(
      blockId: BlockId,
      outputReference: TransactionOutputReference
  ): F[Boolean] =
    OptionT(bss.useStateAt(blockId)(_.get(outputReference.transactionId)))
      .subflatMap(_.lift(outputReference.index))
      .exists(identity)

class TransactionOutputStateBSSImpl[F[_]: Async](
    fetchBody: FetchBody[F],
    fetchTransaction: FetchTransaction[F]
) {

  def makeBss(
      initialState: TransactionOutputState.State[F],
      initialBlockId: BlockId,
      blockIdTree: BlockIdTree[F],
      onBlockChanged: BlockId => F[Unit]
  ): Resource[F, TransactionOutputState.BSS[F]] =
    BlockSourcedState.make[F, TransactionOutputState.State[F]](
      initialState.pure[F],
      initialBlockId.pure[F],
      applyBlock,
      unapplyBlock,
      blockIdTree,
      onBlockChanged
    )

  def applyBlock(
      state: TransactionOutputState.State[F],
      blockId: BlockId
  ): F[TransactionOutputState.State[F]] =
    fetchBody(blockId)
      .map(_.transactionIds)
      .flatMap(
        _.foldLeftM(state)((state, transactionId) =>
          fetchTransaction(transactionId)
            .flatMap(transaction =>
              transaction.inputs.foldLeftM(state)((state, input) =>
                state
                  .getOrRaise(input.reference.transactionId)
                  .map(v => v.updated(input.reference.index, false))
                  .flatMap(updated =>
                    if (updated.contains(true))
                      state.put(input.reference.transactionId, updated)
                    else state.remove(input.reference.transactionId)
                  )
                  .as(state)
              ) *>
                state
                  .put(transactionId, transaction.outputs.as(true).toList)
            )
            .as(state)
        )
      )
      .as(state)
  def unapplyBlock(
      state: TransactionOutputState.State[F],
      blockId: BlockId
  ): F[TransactionOutputState.State[F]] =
    fetchBody(blockId)
      .map(_.transactionIds.reverse)
      .flatMap(
        _.foldLeftM(state)((state, transactionId) =>
          fetchTransaction(transactionId)
            .flatMap(transaction =>
              state.remove(transactionId) *>
                transaction.inputs.foldLeftM(state)((state, input) =>
                  OptionT(state.get(input.reference.transactionId))
                    .getOrElseF(
                      fetchTransaction(input.reference.transactionId)
                        .map(_.outputs.as(false))
                    )
                    .map(_.updated(input.reference.index, true).toList)
                    .flatMap(state.put(input.reference.transactionId, _))
                    .as(state)
                )
            )
            .as(state)
        )
      )
      .as(state)

}
