package com.giraffechain.consensus

import cats.data.OptionT
import cats.effect.{Async, Resource}
import cats.implicits.*
import cats.{Monad, MonadThrow}
import com.giraffechain.*
import com.giraffechain.codecs.given
import com.giraffechain.ledger.*
import com.giraffechain.models.*
import com.giraffechain.utility.Ratio

trait StakerTracker[F[_]]:
  def totalActiveStake(currentBlockId: BlockId, slot: Long): F[Long]
  def staker(
      currentBlockId: BlockId,
      slot: Long,
      account: TransactionOutputReference
  ): F[Option[ActiveStaker]]

  def stakerRelativeStake(
      currentBlockId: BlockId,
      slot: Long,
      account: TransactionOutputReference
  )(using Monad[F]): F[Option[Ratio]] =
    OptionT(staker(currentBlockId, slot, account))
      .semiflatMap(staker => totalActiveStake(currentBlockId, slot).map(Ratio(staker.quantity, _)))
      .value

object StakerTracker:
  def make[F[_]: Async](
      clock: Clock[F],
      genesisBlockId: BlockId,
      consensusDataBSS: StakerData.BSS[F],
      epochBoundariesBSS: EpochBoundaries.BSS[F]
  ): Resource[F, StakerTracker[F]] =
    Resource.pure(
      new StakerTracker[F]:
        override def totalActiveStake(
            currentBlockId: BlockId,
            slot: Slot
        ): F[Slot] = useStateAtBoundary(currentBlockId, slot)(
          _.totalActiveStake.getOrRaise(())
        )

        override def staker(
            currentBlockId: BlockId,
            slot: Long,
            account: TransactionOutputReference
        ): F[Option[ActiveStaker]] =
          useStateAtBoundary(currentBlockId, slot)(_.stakers.get(account))

        private def useStateAtBoundary[Res](
            currentBlockId: BlockId,
            slot: Slot
        )(f: StakerData.State[F] => F[Res]): F[Res] =
          clock
            .epochOf(slot)
            .flatMap(epoch =>
              if (epoch > 1)
                epochBoundariesBSS
                  .stateAt(currentBlockId)
                  .use(
                    _.getOrRaise(epoch - 2)
                  )
              else genesisBlockId.pure[F]
            )
            .flatMap(consensusDataBSS.stateAt(_).use(f))
    )

object StakerData:

  case class State[F[_]](
      totalActiveStake: Store[F, Unit, Long],
      totalInactiveStake: Store[F, Unit, Long],
      stakers: Store[F, TransactionOutputReference, ActiveStaker]
  )

  type BSS[F[_]] = BlockSourcedState[F, State[F]]

  def make[F[_]: Async](
      initialState: F[State[F]],
      currentBlockId: F[BlockId],
      parentChildTree: BlockIdTree[F],
      currentEventChanged: BlockId => F[Unit],
      fetchBlockBody: FetchBody[F],
      fetchTransaction: FetchTransaction[F],
      fetchTransactionOutput: FetchTransactionOutput[F]
  ): Resource[F, BSS[F]] =
    BlockSourcedState.make(
      initialState = initialState,
      initialEventId = currentBlockId,
      applyEvent = new ApplyBlock(fetchBlockBody, fetchTransaction, fetchTransactionOutput),
      unapplyEvent = new UnapplyBlock(fetchBlockBody, fetchTransaction, fetchTransactionOutput),
      parentChildTree = parentChildTree,
      currentEventChanged
    )

  extension [F[_]](state: State[F])
    def modifyTotalActiveStake(f: Long => Long)(using MonadThrow[F]): F[Unit] =
      state.totalActiveStake
        .getOrRaise(())
        .map(f)
        .flatTap(state.totalActiveStake.put((), _))
        .void
    def modifyTotalInactiveStake(
        f: Long => Long
    )(using MonadThrow[F]): F[Unit] =
      state.totalInactiveStake
        .getOrRaise(())
        .map(f)
        .flatTap(state.totalInactiveStake.put((), _))
        .void

  private class ApplyBlock[F[_]: MonadThrow](
      fetchBlockBody: FetchBody[F],
      fetchTransaction: FetchTransaction[F],
      fetchTransactionOutput: FetchTransactionOutput[F]
  ) extends ((State[F], BlockId) => F[State[F]]):

    def apply(state: State[F], blockId: BlockId): F[State[F]] =
      fetchBlockBody(blockId).flatMap(
        _.transactionIds.foldLeftM(state)(applyTransaction)
      )

    private def applyTransaction(
        state: State[F],
        transactionId: TransactionId
    ): F[State[F]] =
      for {
        transaction <- fetchTransaction(transactionId)
        _ <- transaction.inputs.traverseTap(applyInput(state))
        _ <- transaction.referencedOutputs.traverseTap(applyOutput(state))
      } yield state

    private def applyInput(state: State[F])(input: TransactionInput) =
      fetchTransactionOutput(input.reference).flatMap(output =>
        OptionT
          .fromOption(output.account)
          .flatMapF(state.stakers.get)
          .foldF(
            state.modifyTotalInactiveStake(_ - output.quantity)
          )(staker =>
            (if (output.accountRegistration.isEmpty)
               state.stakers.put(
                 input.reference,
                 staker
                   .copy(quantity = staker.quantity - output.quantity)
               )
             else state.stakers.remove(input.reference)) *>
              state.modifyTotalActiveStake(_ - output.quantity)
          )
      )

    private def applyOutput(
        state: State[F]
    )(outputReference: TransactionOutputReference, output: TransactionOutput) =
      OptionT
        .fromOption[F](output.account)
        .flatMap(accountReference =>
          OptionT(state.stakers.get(accountReference))
            .tupleLeft(accountReference)
        )
        .orElse(
          OptionT
            .fromOption[F](
              output.accountRegistration
                .flatMap(_.stakingRegistration)
                .map(ActiveStaker(_))
                .tupleLeft(outputReference)
            )
        )
        .foldF(state.modifyTotalInactiveStake(_ + output.quantity))((account, staker) =>
          state.modifyTotalActiveStake(_ + output.quantity) *>
            state.stakers.put(
              account,
              staker
                .copy(quantity = staker.quantity + output.quantity)
            )
        )

  private class UnapplyBlock[F[_]: MonadThrow](
      fetchBlockBody: FetchBody[F],
      fetchTransaction: FetchTransaction[F],
      fetchTransactionOutput: FetchTransactionOutput[F]
  ) extends ((State[F], BlockId) => F[State[F]]):

    def apply(state: State[F], blockId: BlockId): F[State[F]] =
      fetchBlockBody(blockId).flatMap(
        _.transactionIds.reverse.foldLeftM(state)(unapplyTransaction)
      )

    private def unapplyTransaction(
        state: State[F],
        transactionId: TransactionId
    ): F[State[F]] =
      for {
        transaction <- fetchTransaction(transactionId)
        _ <- transaction.referencedOutputs.reverse.traverseTap(unapplyOutput(state))
        _ <- transaction.inputs.reverse.traverseTap(unapplyInput(state))
      } yield state

    private def unapplyOutput(
        state: State[F]
    )(outputReference: TransactionOutputReference, output: TransactionOutput) =
      OptionT
        .fromOption[F](
          output.accountRegistration.flatMap(_.stakingRegistration)
        )
        .semiflatTap(_ =>
          state.stakers.remove(outputReference) *> state.modifyTotalActiveStake(
            _ - output.quantity
          )
        )
        .void
        .orElse(
          OptionT
            .fromOption[F](output.account)
            .flatMap(accountReference =>
              OptionT(state.stakers.get(accountReference))
                .map(staker =>
                  staker
                    .copy(quantity = staker.quantity - output.quantity)
                )
                .semiflatTap(updatedStaker =>
                  state.stakers.put(accountReference, updatedStaker) *> state
                    .modifyTotalActiveStake(_ - output.quantity)
                )
            )
            .void
        )
        .getOrElseF(
          state.modifyTotalInactiveStake(_ - output.quantity)
        )

    private def unapplyInput(state: State[F])(input: TransactionInput) =
      fetchTransactionOutput(input.reference)
        .flatMap(output =>
          OptionT
            .fromOption(
              output.accountRegistration.flatMap(_.stakingRegistration)
            )
            .semiflatTap(stakingRegistration =>
              state.stakers.put(
                input.reference,
                ActiveStaker(stakingRegistration, output.quantity)
              ) *>
                state.modifyTotalActiveStake(_ + output.quantity)
            )
            .void
            .orElse(
              OptionT
                .fromOption(output.account)
                .semiflatMap(account =>
                  state.stakers
                    .getOrRaise(account)
                    .map(staker => staker.copy(quantity = staker.quantity + output.quantity))
                    .flatMap(newStaker => state.stakers.put(input.reference, newStaker)) *>
                    state.modifyTotalActiveStake(_ + output.quantity)
                )
                .void
            )
            .getOrElseF(
              state.modifyTotalInactiveStake(_ + output.quantity)
            )
        )

object EpochBoundaries:
  type State[F[_]] = Store[F, Epoch, BlockId]
  type BSS[F[_]] = BlockSourcedState[F, State[F]]

  def make[F[_]: Async](
      initialState: F[State[F]],
      currentBlockId: F[BlockId],
      blockIdTree: BlockIdTree[F],
      currentEventChanged: BlockId => F[Unit],
      clock: Clock[F],
      fetchHeader: FetchHeader[F]
  ): Resource[F, BSS[F]] =
    BlockSourcedState.make[F, State[F]](
      initialState = initialState,
      initialEventId = currentBlockId,
      applyEvent = (state, blockId) =>
        fetchHeader(blockId)
          .map(_.slot)
          .flatMap(clock.epochOf)
          .flatTap(state.put(_, blockId))
          .as(state),
      unapplyEvent = (state, blockId) =>
        fetchHeader(blockId)
          .flatMap(header =>
            (
              clock.epochOf(header.slot),
              clock.epochOf(header.parentSlot)
            ).tupled
              .flatMap((epoch, parentEpoch) =>
                if (epoch == parentEpoch)
                  state.put(epoch, header.parentHeaderId)
                else state.remove(epoch)
              )
          )
          .as(state),
      parentChildTree = blockIdTree,
      currentEventChanged
    )
