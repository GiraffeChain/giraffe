package blockchain.consensus

case class Consensus[F[_]](
    headerValidation: HeaderValidation[F],
    chainSelection: ChainSelection[F],
    stakerTracker: StakerTracker[F],
    etaCalculation: EtaCalculation[F],
    leaderElection: LeaderElection[F],
    localChain: LocalChain[F]
)
