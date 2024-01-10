package blockchain.consensus

import blockchain.models.BlockHeader

trait ChainSelection[F[_]]:
  def compare(
      headerX: BlockHeader,
      headerY: BlockHeader,
      commonAncestor: BlockHeader,
      headerAtHeightA: Long => F[Option[BlockHeader]],
      headerAtHeightB: Long => F[Option[BlockHeader]]
  ): F[ChainSelectionOutcome]

sealed trait ChainSelectionOutcome:
  def isX: Boolean
  def isY: Boolean

object ChainSelectionOutcome:
  sealed trait XChainSelectionOutcome:
    self: ChainSelectionOutcome =>
    def isX = true
    def isY = false

  sealed trait YChainSelectionOutcome:
    self: ChainSelectionOutcome =>
    def isX = false
    def isY = true

  case object XStandard
      extends ChainSelectionOutcome
      with XChainSelectionOutcome

  case object YStandard
      extends ChainSelectionOutcome
      with YChainSelectionOutcome

  case object XDensity extends ChainSelectionOutcome with XChainSelectionOutcome

  case object YDensity extends ChainSelectionOutcome with YChainSelectionOutcome
