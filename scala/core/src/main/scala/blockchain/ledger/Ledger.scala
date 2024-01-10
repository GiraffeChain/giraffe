package blockchain.ledger

case class Ledger[F[_]](
    transactionValidation: TransactionValidation[F],
    bodyValidation: BodyValidation[F],
    headerToBodyValidation: HeaderToBodyValidation[F],
    mempool: Mempool[F],
    transactionOutputState: TransactionOutputState[F],
    blockPacker: BlockPacker[F]
)
