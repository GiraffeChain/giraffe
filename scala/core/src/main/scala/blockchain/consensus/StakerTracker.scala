package blockchain.consensus

import blockchain.models.{BlockId, StakingAddress}
import blockchain.utility.Ratio

trait StakerTracker[F[_]]:
  def totalActiveStake(currentBlockId: BlockId, slot: Long): F[Long]
  def staker(
      currentBlockId: BlockId,
      slot: Long,
      address: StakingAddress
  ): F[Option[Ratio]]
