package com.giraffechain.ledger

import cats.effect.{Async, Resource}
import cats.implicits.*
import com.giraffechain.codecs.given
import com.giraffechain.consensus.LocalChain
import com.giraffechain.crypto.CryptoResources
import com.giraffechain.{BlockIdTree, Clock, DataStores, EventIdGetterSetters}

case class Ledger[F[_]](
    transactionValidation: TransactionValidation[F],
    bodyValidation: BodyValidation[F],
    headerToBodyValidation: HeaderToBodyValidation[F],
    mempool: Mempool[F],
    transactionOutputState: TransactionOutputState[F],
    accountState: AccountState[F],
    addressState: AddressState[F],
    blockPacker: BlockPacker[F],
    graphState: GraphState[F],
    transactionHeightState: TransactionHeightState[F]
)

object Ledger:
  def make[F[_]: Async: CryptoResources](
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
      addressStateBSS <- AddressState.makeBSS(
        dataStores.addresses.pure[F],
        eventIdGetterSetters.accountState.get(),
        blockIdTree,
        eventIdGetterSetters.accountState.set,
        dataStores.bodies.getOrRaise,
        dataStores.transactions.getOrRaise,
        dataStores.transactionOutputs.getOrRaise
      )
      accountState <- AccountState.make(accountStateBSS)
      addressState <- AddressState.make(addressStateBSS)
      transactionOutputStateBSS <- TransactionOutputState.makeBSS(
        dataStores.spendableOutputs.pure[F],
        eventIdGetterSetters.transactionOutputState.get(),
        blockIdTree,
        eventIdGetterSetters.transactionOutputState.set,
        dataStores.bodies.getOrRaise,
        dataStores.transactions.getOrRaise
      )
      transactionOutputState <- TransactionOutputState.make(transactionOutputStateBSS)
      valueCalculator <- ValueCalculatorImpl.make[F]
      transactionValidation <- TransactionValidation
        .make[F](
          dataStores.transactions.getOrRaise,
          dataStores.transactionOutputs.getOrRaise,
          transactionOutputState,
          accountState,
          valueCalculator
        )
      bodyValidation <- BodyValidation.make[F](transactionValidation)
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
        clock,
        transaction => dataStores.transactions.put(transaction.id, transaction)
      )
      headerToBodyValidation <- HeaderToBodyValidation.make[F](dataStores.headers.getOrRaise)
      graphStateBSS <- GraphState.makeBSS[F](
        dataStores.sqlite,
        eventIdGetterSetters.graphState.get(),
        blockIdTree,
        eventIdGetterSetters.graphState.set,
        dataStores.bodies.getOrRaise,
        dataStores.transactions.getOrRaise,
        dataStores.transactionOutputs.getOrRaise
      )
      graphState <- GraphState.make(graphStateBSS)
      transactionHeightsBSS <- TransactionHeightState.makeBSS(
        dataStores.transactionHeights.pure[F],
        eventIdGetterSetters.transactionHeightState.get(),
        blockIdTree,
        eventIdGetterSetters.transactionHeightState.set,
        dataStores.headers.getOrRaise,
        dataStores.bodies.getOrRaise
      )
      transactionHeightState <- TransactionHeightState.make(transactionHeightsBSS)
    } yield Ledger(
      transactionValidation,
      bodyValidation,
      headerToBodyValidation,
      mempoolBlockPacker,
      transactionOutputState,
      accountState,
      addressState,
      mempoolBlockPacker,
      graphState,
      transactionHeightState
    )
