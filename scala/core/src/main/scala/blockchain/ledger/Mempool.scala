package blockchain.ledger

import blockchain.*
import blockchain.consensus.*
import blockchain.codecs.given
import blockchain.models.*
import cats.implicits.*
import cats.effect.Async
import fs2.concurrent.Topic

import java.time.Instant

trait Mempool[F[_]]:
  def read: F[List[Transaction]]
  def add(transaction: Transaction): F[Unit]
  def changes: fs2.Stream[F, MempoolChange]

object Mempool:
  class State(var entries: List[Entry])
  case class Entry(transaction: Transaction, addedAt: Instant)
  type BSS[F[_]] = BlockSourcedState[F, State]

sealed trait MempoolChange
object MempoolChange:
  case class Added(transaction: Transaction) extends MempoolChange
  case class Removed(transaction: Transaction) extends MempoolChange

class MempoolImpl[F[_]: Async](
    bss: Mempool.BSS[F],
    localChain: LocalChain[F],
    fetchHeader: FetchHeader[F],
    bodyValidation: BodyValidation[F],
    clock: Clock[F],
    mempoolChangesTopic: Topic[F, MempoolChange]
) extends Mempool[F]
    with BlockPacker[F]:
  override def read: F[List[Transaction]] =
    localChain.currentHead
      .flatMap(
        bss.useStateAt(_)(state =>
          retainValid(state.entries.map(_.transaction)).flatTap(updated =>
            Async[F].delay(state.entries =
              updated.flatMap(u => state.entries.find(_.transaction.id == u.id))
            )
          )
        )
      )

  // TODO: Validate
  override def add(transaction: Transaction): F[Unit] =
    localChain.currentHead
      .flatMap(
        bss.useStateAt(_)(s =>
          Async[F].delay(s.entries =
            s.entries :+ Mempool.Entry(transaction, Instant.now())
          )
        )
      )

  override def changes: fs2.Stream[F, MempoolChange] =
    mempoolChangesTopic.subscribeUnbounded

  override def streamed: fs2.Stream[F, FullBlockBody] =
    localChain.adoptions.void
      .merge(changes.void)
      .evalMap(_ => read)
      .map(FullBlockBody(_))

  private def retainValid(
      transactions: List[Transaction]
  ): F[List[Transaction]] =
    for {
      headId <- localChain.currentHead
      head <- fetchHeader(headId)
      slot <- clock.globalSlot
      newTransactions <- transactions.foldLeftM(
        List.empty[Transaction]
      )((transactions, transaction) =>
        bodyValidation
          .validate(
            BlockBody(transactions.map(_.id) :+ transaction.id),
            TransactionValidationContext(headId, head.height + 1, slot)
          )
          .fold(_ => transactions, _ => transactions :+ transaction)
      )
    } yield newTransactions
