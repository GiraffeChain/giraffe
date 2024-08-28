package blockchain.ledger

import blockchain.*
import blockchain.codecs.given
import blockchain.models.*
import cats.data.OptionT
import cats.effect.{Async, MonadCancelThrow, Resource}
import cats.implicits.*
import scodec.bits.BitVector

trait TransactionOutputState[F[_]]:
  def transactionOutputIsSpendable(blockId: BlockId, outputReference: TransactionOutputReference): F[Boolean]

object TransactionOutputState:
  type State[F[_]] = Store[F, TransactionId, BitVector]
  type BSS[F[_]] = BlockSourcedState[F, State[F]]

  def make[F[_]: MonadCancelThrow](bss: BSS[F]): Resource[F, TransactionOutputState[F]] =
    Resource.pure(new TransactionOutputStateImpl[F](bss))

  def makeBSS[F[_]: Async](
      initialState: F[State[F]],
      initialBlockId: F[BlockId],
      blockIdTree: BlockIdTree[F],
      onBlockChanged: BlockId => F[Unit],
      fetchBody: FetchBody[F],
      fetchTransaction: FetchTransaction[F]
  ): Resource[F, BSS[F]] =
    new TransactionOutputStateBSSImpl[F](fetchBody, fetchTransaction).makeBss(
      initialState,
      initialBlockId,
      blockIdTree,
      onBlockChanged
    )

class TransactionOutputStateImpl[F[_]: MonadCancelThrow](bss: TransactionOutputState.BSS[F])
    extends TransactionOutputState[F]:
  override def transactionOutputIsSpendable(
      blockId: BlockId,
      outputReference: TransactionOutputReference
  ): F[Boolean] =
    OptionT
      .fromOption(outputReference.transactionId)
      .getOrRaise(new IllegalArgumentException("Illegal SelfSpend"))
      .flatMap(transactionId =>
        OptionT(bss.stateAt(blockId).use(_.get(transactionId)))
          .subflatMap(_.lift(outputReference.index))
          .exists(identity)
      )

class TransactionOutputStateBSSImpl[F[_]: Async](fetchBody: FetchBody[F], fetchTransaction: FetchTransaction[F]):
  def makeBss(
      initialState: F[TransactionOutputState.State[F]],
      initialBlockId: F[BlockId],
      blockIdTree: BlockIdTree[F],
      onBlockChanged: BlockId => F[Unit]
  ): Resource[F, TransactionOutputState.BSS[F]] =
    BlockSourcedState.make[F, TransactionOutputState.State[F]](
      initialState,
      initialBlockId,
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
                OptionT
                  .fromOption[F](input.reference.transactionId)
                  .getOrRaise(new IllegalArgumentException("Illegal SelfSpend"))
                  .flatMap(transactionId =>
                    state
                      .getOrRaise(transactionId)
                      .map(v => v.clear(input.reference.index))
                      .flatMap(updated =>
                        if (updated.populationCount > 1)
                          state.put(transactionId, updated)
                        else state.remove(transactionId)
                      )
                  )
                  .as(state)
              ) *>
                state.put(transactionId, BitVector.high(transaction.outputs.length))
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
                transaction.inputs.reverse.foldLeftM(state)((state, input) =>
                  OptionT
                    .fromOption[F](input.reference.transactionId)
                    .getOrRaise(new IllegalArgumentException("Illegal SelfSpend"))
                    .flatMap(transactionId =>
                      OptionT(state.get(transactionId))
                        .getOrElseF(
                          fetchTransaction(transactionId)
                            .map(_.outputs.length)
                            .map(BitVector.low(_))
                        )
                        .map(_.set(input.reference.index))
                        .flatMap(state.put(transactionId, _))
                        .as(state)
                    )
                )
            )
            .as(state)
        )
      )
      .as(state)
