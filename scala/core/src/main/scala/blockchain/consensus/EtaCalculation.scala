package blockchain.consensus

import blockchain.models.SlotId

trait EtaCalculation[F[_]]:
  def etaToBe(parentslotId: SlotId, childSlot: Long): F[Eta]
