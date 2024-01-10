package blockchain.ledger

import blockchain.models.Transaction

trait Mempool[F[_]] {
  def read: F[Set[Transaction]]
  def add(transaction: Transaction): F[Unit]
  def changes: fs2.Stream[F, MempoolChange]
}

sealed trait MempoolChange
object MempoolChange:
  case class Added(transaction: Transaction) extends MempoolChange
  case class Removed(transaction: Transaction) extends MempoolChange
