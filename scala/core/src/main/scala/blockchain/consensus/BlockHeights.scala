package blockchain.consensus

import blockchain.{BlockIdTree, BlockSourcedState}
import blockchain.models.*
import blockchain.Store
import cats.effect.{Async, Resource}
import cats.implicits.*

object BlockHeights:
  type State[F[_]] = Long => F[Option[BlockId]]
  type BSS[F[_]] = BlockSourcedState[F, State[F]]

  def make[F[_]: Async](
      store: Store[F, Long, BlockId],
      initialEventId: F[BlockId],
      blockTree: BlockIdTree[F],
      currentEventChanged: BlockId => F[Unit],
      fetchHeader: BlockId => F[BlockHeader]
  ): Resource[F, BSS[F]] =
    BlockSourcedState.make[F, State[F]](
      Async[F].delay(store.get),
      initialEventId = initialEventId,
      (state, id) => fetchHeader(id).map(_.height).flatTap(store.put(_, id)).as(state),
      (state, id) => fetchHeader(id).map(_.height).flatTap(store.remove).as(state),
      blockTree,
      currentEventChanged
    )
