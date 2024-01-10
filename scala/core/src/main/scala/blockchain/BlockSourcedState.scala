package blockchain

import blockchain.models.BlockId

trait BlockSourcedState[F[_], State]:
  def useStateAt[U](blockId: BlockId)(f: State => F[U]): F[U]
