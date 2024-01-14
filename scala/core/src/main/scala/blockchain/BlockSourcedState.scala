package blockchain

import blockchain.models.BlockId
import cats.data.Chain
import cats.implicits.*
import cats.effect.implicits.*
import cats.effect.{Async, Ref, Resource}
import cats.effect.std.{Mutex, Semaphore}

trait BlockSourcedState[F[_], State]:
  def useStateAt[U](blockId: BlockId)(f: State => F[U]): F[U]

object BlockSourcedState:
  def make[F[_]: Async, State](
      initialState: F[State],
      initialEventId: F[BlockId],
      applyEvent: (State, BlockId) => F[State],
      unapplyEvent: (State, BlockId) => F[State],
      parentChildTree: BlockIdTree[F],
      currentEventChanged: BlockId => F[Unit]
  ): Resource[F, BlockSourcedState[F, State]] =
    (
      Mutex[F],
      initialState.flatMap(Ref.of[F, State]),
      initialEventId.flatMap(Ref.of[F, BlockId])
    )
      .mapN((mutex, stateRef, idRef) =>
        new TreeBlockSourcedState[F, State](
          applyEvent,
          unapplyEvent,
          parentChildTree,
          mutex,
          stateRef,
          idRef,
          currentEventChanged
        )
      )
      .toResource

class TreeBlockSourcedState[F[_]: Async, State](
    applyEvent: (State, BlockId) => F[State],
    unapplyEvent: (State, BlockId) => F[State],
    parentChildTree: BlockIdTree[F],
    mutex: Mutex[F],
    currentStateRef: Ref[F, State],
    currentEventIdRef: Ref[F, BlockId],
    currentEventChanged: BlockId => F[Unit]
) extends BlockSourcedState[F, State]:
  def useStateAt[U](blockId: BlockId)(f: State => F[U]): F[U] =
    mutex.lock.surround(
      for {
        currentEventId <- currentEventIdRef.get
        state <-
          (currentEventId == blockId)
            .pure[F]
            .ifM(
              currentStateRef.get,
              for {
                (unapplyChain, applyChain) <- parentChildTree.findCommonAncestor(currentEventId, blockId)
                currentState <- currentStateRef.get
                stateAtCommonAncestor <- unapplyEvents(
                  unapplyChain.tail,
                  currentState,
                  unapplyChain.head
                )
                newState <- applyEvents(applyChain.tail, stateAtCommonAncestor)
              } yield newState
            )
        res <- f(state)
      } yield res
    )

  private def unapplyEvents(
      eventIds: Chain[BlockId],
      currentState: State,
      newEventId: BlockId
  ): F[State] =
    eventIds.zipWithIndex.reverse.foldLeftM(currentState) {
      case (state, (eventId, index)) =>
        Async[F].uncancelable(_ =>
          for {
            newState <- unapplyEvent(state, eventId)
            nextEventId = eventIds.get(index - 1).getOrElse(newEventId)
            _ <- (
              currentStateRef.set(newState),
              currentEventIdRef.set(nextEventId),
              currentEventChanged(nextEventId)
            ).tupled
          } yield newState
        )
    }

  private def applyEvents(
      eventIds: Chain[BlockId],
      currentState: State
  ): F[State] =
    eventIds.foldLeftM(currentState) { case (state, eventId) =>
      Async[F].uncancelable(_ =>
        for {
          newState <- applyEvent(state, eventId)
          _ <- (
            currentStateRef.set(newState),
            currentEventIdRef.set(eventId),
            currentEventChanged(eventId)
          ).tupled
        } yield newState
      )
    }
