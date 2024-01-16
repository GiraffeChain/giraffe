package blockchain.ledger

import blockchain.consensus.LocalChain
import blockchain.{BlockIdTree, Clock, DataStores, EventIdGetterSetters}
import blockchain.codecs.given
import cats.effect.{Async, Resource}
import cats.implicits.*

case class Ledger[F[_]](
    transactionValidation: TransactionValidation[F],
    bodyValidation: BodyValidation[F],
    headerToBodyValidation: HeaderToBodyValidation[F],
    mempool: Mempool[F],
    transactionOutputState: TransactionOutputState[F],
    accountState: AccountState[F],
    blockPacker: BlockPacker[F]
)

object Ledger:
  def make[F[_]: Async](
      dataStores: DataStores[F],
      eventIdGetterSetters: EventIdGetterSetters[F],
      blockIdTree: BlockIdTree[F],
      clock: Clock[F],
      localChain: LocalChain[F]
  ): Resource[F, Ledger[F]] =
    for {
      accountStateBSS <- AccountState.makeBSS(
        dataStores.accounts.pure[F],
        eventIdGetterSetters.accountState.get(),
        blockIdTree,
        eventIdGetterSetters.accountState.set,
        dataStores.bodies.getOrRaise,
        dataStores.transactions.getOrRaise,
        dataStores.transactionOutputs.getOrRaise
      )
      accountState <- AccountState.make(accountStateBSS)
      transactionOutputStateBSS <- TransactionOutputState.makeBSS(
        dataStores.spendableOutputs.pure[F],
        eventIdGetterSetters.transactionOutputState.get(),
        blockIdTree,
        eventIdGetterSetters.transactionOutputState.set,
        dataStores.bodies.getOrRaise,
        dataStores.transactions.getOrRaise
      )
      transactionOutputState <- TransactionOutputState.make(
        transactionOutputStateBSS
      )
      transactionValidation <- TransactionValidation.make[F](
        dataStores.transactions.getOrRaise,
        transactionOutputState,
        accountState
      )
      bodyValidation <- BodyValidation
        .make[F](dataStores.transactions.getOrRaise, transactionValidation)
      mempoolBSS <- Mempool.makeBSS[F](
        Mempool.State.default.pure[F],
        localChain.currentHead,
        blockIdTree,
        _ => ().pure[F],
        dataStores.bodies.getOrRaise,
        dataStores.transactions.getOrRaise
      )
      mempoolBlockPacker <- Mempool.make(
        mempoolBSS,
        localChain,
        dataStores.headers.getOrRaise,
        bodyValidation,
        clock
      )
      headerToBodyValidation <- HeaderToBodyValidation.make[F]()
    } yield Ledger(
      transactionValidation,
      bodyValidation,
      headerToBodyValidation,
      mempoolBlockPacker,
      transactionOutputState,
      accountState,
      mempoolBlockPacker
    )
