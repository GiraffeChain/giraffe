package blockchain.ledger

import blockchain.models.{BlockId, FullBlockBody}

trait BlockPacker[F[_]]:
  def streamed(
      parentBlockId: BlockId,
      height: Long,
      slot: Long
  ): fs2.Stream[F, FullBlockBody]
