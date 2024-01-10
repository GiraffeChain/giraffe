package blockchain.consensus

import blockchain.utility.Ratio

trait LeaderElection[F[_]]:
  def getThreshold(relativeStake: Ratio, slotDiff: Long): F[Ratio]
  def isEligible(threshold: Ratio, rho: Rho): F[Boolean]
