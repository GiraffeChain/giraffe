package blockchain.ledger

import blockchain.*
import blockchain.models.*
import blockchain.utility.given
import blockchain.codecs.given
import blockchain.ledger.given
import cats.{Functor, MonadThrow}
import cats.data.OptionT
import cats.effect.{Async, Resource}
import cats.implicits.*

trait AccountState[F[_]] {

  def accountUtxos(
      parentBlockId: BlockId,
      account: TransactionOutputReference
  ): F[Option[List[TransactionOutputReference]]]

}

object AccountState:
  type State[F[_]] =
    Store[F, TransactionOutputReference, List[TransactionOutputReference]]
  type BSS[F[_]] = BlockSourcedState[F, State[F]]

  def makeBSS[F[_]: Async](
      initialState: State[F],
      initialBlockId: BlockId,
      fetchBody: FetchBody[F],
      fetchTransaction: FetchTransaction[F],
      fetchTransactionOutput: FetchTransactionOutput[F],
      blockIdTree: BlockIdTree[F],
      onBlockChanged: BlockId => F[Unit]
  ): Resource[F, BSS[F]] =
    new AccountStateBSSImpl[F](
      fetchBody,
      fetchTransaction,
      fetchTransactionOutput
    )
      .makeBss(
        initialState,
        initialBlockId,
        blockIdTree,
        onBlockChanged
      )

class AccountStateImpl[F[_]: Functor](bss: AccountState.BSS[F])
    extends AccountState[F]:
  override def accountUtxos(
      parentBlockId: BlockId,
      account: TransactionOutputReference
  ): F[Option[List[TransactionOutputReference]]] =
    bss.useStateAt(parentBlockId)(_.get(account))

class AccountStateBSSImpl[F[_]: Async](
    fetchBody: FetchBody[F],
    fetchTransaction: FetchTransaction[F],
    fetchTransactionOutput: FetchTransactionOutput[F]
):
  def makeBss(
      initialState: AccountState.State[F],
      initialBlockId: BlockId,
      blockIdTree: BlockIdTree[F],
      onBlockChanged: BlockId => F[Unit]
  ): Resource[F, AccountState.BSS[F]] =
    BlockSourcedState.make[F, AccountState.State[F]](
      initialState.pure[F],
      initialBlockId.pure[F],
      applyBlock,
      unapplyBlock,
      blockIdTree,
      onBlockChanged
    )

  def applyBlock(
      state: AccountState.State[F],
      blockId: BlockId
  ): F[AccountState.State[F]] =
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
      state: AccountState.State[F],
      input: TransactionInput
  ) =
    OptionT(fetchTransactionOutput(input.reference).map(_.account))
      .semiflatTap(account =>
        state
          .getOrRaise(account)
          .map(_.filterNot(_ == input.reference))
          .flatMap(state.put(account, _))
      )
      .void
      .orElse(
        OptionT
          .fromOption[F](input.value.accountRegistration)
          .semiflatTap(_ => state.remove(input.reference))
          .void
      )
      .value
      .as(state)

  private def applyReferencedOutput(
      state: AccountState.State[F],
      referencedOutput: (TransactionOutputReference, TransactionOutput)
  ) = {
    val (outputReference, output) = referencedOutput
    OptionT
      .fromOption[F](output.account)
      .semiflatTap(account =>
        state
          .getOrRaise(account)
          .map(_ :+ outputReference)
          .flatTap(state.put(account, _))
      )
      .void
      .orElse(
        OptionT
          .fromOption[F](output.value.accountRegistration)
          .semiflatTap(_ => state.put(outputReference, Nil))
          .void
      )
      .value
      .as(state)
  }

  def unapplyBlock(
      state: AccountState.State[F],
      blockId: BlockId
  ): F[AccountState.State[F]] =
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
      state: AccountState.State[F],
      input: TransactionInput
  ) =
    OptionT(fetchTransactionOutput(input.reference).map(_.account))
      .semiflatTap(account =>
        state
          .getOrRaise(account)
          .map(_ :+ input.reference)
          .flatMap(state.put(account, _))
      )
      .void
      .orElse(
        OptionT
          .fromOption[F](input.value.accountRegistration)
          .semiflatTap(_ => state.put(input.reference, Nil))
          .void
      )
      .value
      .as(state)

  private def unapplyReferencedOutput(
      state: AccountState.State[F],
      referencedOutput: (TransactionOutputReference, TransactionOutput)
  ) = {
    val (outputReference, output) = referencedOutput
    OptionT
      .fromOption[F](output.account)
      .semiflatTap(account =>
        state
          .getOrRaise(account)
          .map(_.filterNot(_ == outputReference))
          .flatTap(state.put(account, _))
      )
      .void
      .orElse(
        OptionT
          .fromOption[F](output.value.accountRegistration)
          .semiflatTap(_ => state.remove(outputReference))
          .void
      )
      .value
      .as(state)
  }
