package blockchain.ledger

import blockchain.models.{BlockId, TransactionOutputReference}

trait TransactionOutputState[F[_]] {

  def transactionOutputIsSpendable(
      blockId: BlockId,
      outputReference: TransactionOutputReference
  ): F[Boolean]

}
