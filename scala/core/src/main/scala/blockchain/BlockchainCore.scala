package blockchain

import blockchain.consensus.Consensus
import blockchain.ledger.Ledger

case class BlockchainCore[F[_]](
    clock: Clock[F],
    dataStores: DataStores[F],
    blockIdTree: BlockIdTree[F],
    consensus: Consensus[F],
    ledger: Ledger[F]
)
