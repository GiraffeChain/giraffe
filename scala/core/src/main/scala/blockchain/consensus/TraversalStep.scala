package blockchain.consensus

import blockchain.models.BlockId

sealed trait TraversalStep:
  def id: BlockId

object TraversalStep:
  case class Applied(id: BlockId) extends TraversalStep
  case class Unapplied(id: BlockId) extends TraversalStep
