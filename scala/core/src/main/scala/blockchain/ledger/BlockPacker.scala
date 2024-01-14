package blockchain.ledger

import blockchain.models.{BlockId, FullBlockBody}

trait BlockPacker[F[_]]:
  def streamed: fs2.Stream[F, FullBlockBody]
