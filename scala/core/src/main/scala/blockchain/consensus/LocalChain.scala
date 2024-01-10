package blockchain.consensus

import blockchain.models.BlockId

trait LocalChain[F[_]]:
  def adopt(blockId: BlockId): F[Unit]
  def currentHead: F[BlockId]
  def genesis: F[BlockId]
  def adoptions: fs2.Stream[F, BlockId]
  def blockIdAtHeight(height: Long): F[Option[BlockId]]
