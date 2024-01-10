package blockchain

import blockchain.models._

trait Store[F[_], Key, T]:
  def get(key: Key): F[T]
  def contains(key: Key): F[Boolean]
  def put(key: Key, value: T): F[Unit]
  def remove(key: Key): F[Unit]

case class DataStores[F[_]](
    parentChildTree: Store[F, BlockId, (Long, BlockId)],
    currentEventIds: Store[F, Byte, BlockId],
    headers: Store[F, BlockId, BlockHeader],
    bodies: Store[F, BlockId, BlockBody],
    transactions: Store[F, TransactionId, Transaction],
    spendableOutputs: Store[F, TransactionId, Array[Boolean]],
    epochBoundaries: Store[F, Long, BlockId],
    activeStake: Store[F, Unit, Long],
    inactiveStake: Store[F, Unit, Long],
    stakers: Store[F, Unit, ActiveStaker],
    blockHeightIndex: Store[F, Long, BlockId],
    metadata: Store[F, String, Array[Byte]]
)
