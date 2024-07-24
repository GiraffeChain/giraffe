package blockchain.ledger

import blockchain.*
import blockchain.codecs.{given}
import blockchain.models.*
import cats.data.OptionT
import cats.effect.kernel.MonadCancelThrow
import cats.effect.{Async, Resource}
import cats.implicits.*

trait AddressState[F[_]] {

  def addressUtxos(
      parentBlockId: BlockId,
      address: LockAddress
  ): F[Option[List[TransactionOutputReference]]]

}

object AddressState:
  type State[F[_]] =
    Store[F, LockAddress, List[TransactionOutputReference]]
  type BSS[F[_]] = BlockSourcedState[F, State[F]]

  def make[F[_]: MonadCancelThrow](bss: BSS[F]): Resource[F, AddressState[F]] =
    Resource.pure(new AddressStateImpl[F](bss))

  def makeBSS[F[_]: Async](
      initialState: F[State[F]],
      initialBlockId: F[BlockId],
      blockIdTree: BlockIdTree[F],
      onBlockChanged: BlockId => F[Unit],
      fetchBody: FetchBody[F],
      fetchTransaction: FetchTransaction[F],
      fetchTransactionOutput: FetchTransactionOutput[F]
  ): Resource[F, BSS[F]] =
    new AddressStateBSSImpl[F](fetchBody, fetchTransaction, fetchTransactionOutput)
      .makeBss(initialState, initialBlockId, blockIdTree, onBlockChanged)

class AddressStateImpl[F[_]: MonadCancelThrow](bss: AddressState.BSS[F]) extends AddressState[F]:
  override def addressUtxos(
      parentBlockId: BlockId,
      address: LockAddress
  ): F[Option[List[TransactionOutputReference]]] =
    bss.stateAt(parentBlockId).use(_.get(address))

class AddressStateBSSImpl[F[_]: Async](
    fetchBody: FetchBody[F],
    fetchTransaction: FetchTransaction[F],
    fetchTransactionOutput: FetchTransactionOutput[F]
):
  def makeBss(
      initialState: F[AddressState.State[F]],
      initialBlockId: F[BlockId],
      blockIdTree: BlockIdTree[F],
      onBlockChanged: BlockId => F[Unit]
  ): Resource[F, AddressState.BSS[F]] =
    BlockSourcedState.make[F, AddressState.State[F]](
      initialState,
      initialBlockId,
      applyBlock,
      unapplyBlock,
      blockIdTree,
      onBlockChanged
    )

  def applyBlock(
      state: AddressState.State[F],
      blockId: BlockId
  ): F[AddressState.State[F]] =
    fetchBody(blockId)
      .map(_.transactionIds)
      .flatMap(
        _.foldLeftM(state)((state, transactionId) =>
          fetchTransaction(transactionId).flatMap(transaction =>
            transaction.inputs.foldLeftM(state)(applyInput) >>
              transaction.referencedOutputs
                .foldLeftM(state)(applyReferencedOutput)
          )
        )
      )

  private def applyInput(
      state: AddressState.State[F],
      input: TransactionInput
  ) =
    fetchTransactionOutput(input.reference)
      .map(_.lockAddress)
      .flatMap(address =>
        state
          .getOrRaise(address)
          .map(_.filterNot(_ == input.reference))
          .flatMap(state.put(address, _))
      )
      .void
      .as(state)

  private def applyReferencedOutput(
      state: AddressState.State[F],
      referencedOutput: (TransactionOutputReference, TransactionOutput)
  ) = {
    val (outputReference, output) = referencedOutput
    OptionT(
      state
        .get(output.lockAddress)
    ).getOrElse(Nil)
      .map(_ :+ outputReference)
      .flatTap(state.put(output.lockAddress, _))
      .as(state)
  }

  def unapplyBlock(
      state: AddressState.State[F],
      blockId: BlockId
  ): F[AddressState.State[F]] =
    fetchBody(blockId)
      .map(_.transactionIds.reverse)
      .flatMap(
        _.foldLeftM(state)((state, transactionId) =>
          fetchTransaction(transactionId).flatMap(transaction =>
            transaction.referencedOutputs.reverse
              .foldLeftM(state)(unapplyReferencedOutput) >>
              transaction.inputs.reverse.foldLeftM(state)(unapplyInput)
          )
        )
      )

  private def unapplyInput(
      state: AddressState.State[F],
      input: TransactionInput
  ) =
    fetchTransactionOutput(input.reference)
      .map(_.lockAddress)
      .flatMap(address =>
        OptionT(
          state
            .get(address)
        ).getOrElse(Nil)
          .map(_ :+ input.reference)
          .flatMap(state.put(address, _))
      )
      .as(state)

  private def unapplyReferencedOutput(
      state: AddressState.State[F],
      referencedOutput: (TransactionOutputReference, TransactionOutput)
  ) = {
    val (outputReference, output) = referencedOutput
    state
      .getOrRaise(output.lockAddress)
      .map(_.filterNot(_ == outputReference))
      .flatTap(state.put(output.lockAddress, _))
      .as(state)
  }
