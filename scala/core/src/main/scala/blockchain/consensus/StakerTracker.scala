package blockchain.consensus

import blockchain.*
import blockchain.codecs.given
import blockchain.models.*
import blockchain.utility.Ratio
import cats.data.OptionT
import cats.effect.{Async, Resource}
import cats.implicits.*
import cats.{Monad, MonadThrow}

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
      fetchTransaction: FetchTransaction[F]
  ): Resource[F, BSS[F]] =
    BlockSourcedState.make(
      initialState = initialState,
      initialEventId = currentBlockId,
      applyEvent = new ApplyBlock(fetchBlockBody, fetchTransaction),
      unapplyEvent = new UnapplyBlock(fetchBlockBody, fetchTransaction),
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
      fetchBlockBody: BlockId => F[BlockBody],
      fetchTransaction: TransactionId => F[Transaction]
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
        _ <- transaction.outputs.zipWithIndex.traverseTap((output, index) =>
          applyOutput(state)(
            TransactionOutputReference(transactionId, index),
            output
          )
        )
      } yield state

    private def applyInput(state: State[F])(input: TransactionInput) =
      OptionT(
        fetchTransaction(input.reference.transactionId)
          .map(_.outputs(input.reference.index).account)
      ).flatMapF(state.stakers.get)
        .foldF(
          state.modifyTotalInactiveStake(_ - input.value.quantity)
        )(staker =>
          (if (input.value.accountRegistration.isEmpty)
             state.stakers.put(
               input.reference,
               staker
                 .copy(quantity = staker.quantity - input.value.quantity)
             )
           else state.stakers.remove(input.reference)) *>
            state.modifyTotalActiveStake(_ - input.value.quantity)
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
              output.value.accountRegistration
                .flatMap(_.stakingRegistration)
                .map(ActiveStaker(_))
                .tupleLeft(outputReference)
            )
        )
        .foldF(state.modifyTotalInactiveStake(_ + output.value.quantity))((account, staker) =>
          state.modifyTotalActiveStake(_ + output.value.quantity) *>
            state.stakers.put(
              account,
              staker
                .copy(quantity = staker.quantity + output.value.quantity)
            )
        )

  private class UnapplyBlock[F[_]: MonadThrow](
      fetchBlockBody: BlockId => F[BlockBody],
      fetchTransaction: TransactionId => F[Transaction]
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
        _ <- transaction.outputs.zipWithIndex.reverse.traverseTap((output, index) =>
          unapplyOutput(state)(
            TransactionOutputReference(transactionId, index),
            output
          )
        )
        _ <- transaction.inputs.reverse.traverseTap(unapplyInput(state))
      } yield state

    private def unapplyOutput(
        state: State[F]
    )(outputReference: TransactionOutputReference, output: TransactionOutput) =
      OptionT
        .fromOption[F](
          output.value.accountRegistration.flatMap(_.stakingRegistration)
        )
        .semiflatTap(_ =>
          state.stakers.remove(outputReference) *> state.modifyTotalActiveStake(
            _ - output.value.quantity
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
                    .copy(quantity = staker.quantity - output.value.quantity)
                )
                .semiflatTap(updatedStaker =>
                  state.stakers.put(accountReference, updatedStaker) *> state
                    .modifyTotalActiveStake(_ - output.value.quantity)
                )
            )
            .void
        )
        .getOrElseF(
          state.modifyTotalInactiveStake(_ - output.value.quantity)
        )

    private def unapplyInput(state: State[F])(input: TransactionInput) =
      OptionT
        .fromOption(
          input.value.accountRegistration.flatMap(_.stakingRegistration)
        )
        .semiflatTap(stakingRegistration =>
          state.stakers.put(
            input.reference,
            ActiveStaker(stakingRegistration, input.value.quantity)
          ) *>
            state.modifyTotalActiveStake(_ + input.value.quantity)
        )
        .void
        .orElse(
          OptionT
            .liftF(fetchTransaction(input.reference.transactionId))
            .map(_.outputs(input.reference.index))
            .subflatMap(_.account)
            .semiflatMap(account =>
              state.stakers
                .getOrRaise(account)
                .map(staker => staker.copy(quantity = staker.quantity + input.value.quantity))
                .flatMap(newStaker => state.stakers.put(input.reference, newStaker)) *>
                state.modifyTotalActiveStake(_ + input.value.quantity)
            )
            .void
        )
        .getOrElseF(
          state.modifyTotalInactiveStake(_ + input.value.quantity)
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
  ) =
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
