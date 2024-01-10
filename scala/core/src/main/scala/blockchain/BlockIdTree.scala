package blockchain

import blockchain.models.BlockId

trait BlockIdTree[F[_]]:
  def parentOf(blockId: BlockId): F[Option[BlockId]]
  def associate( child: BlockId, parent: BlockId): F[Unit]
  def heightOf(t: BlockId): F[Long]
  def findCommonAncestor(a: BlockId, b: BlockId): F[(List[BlockId], List[BlockId])]
