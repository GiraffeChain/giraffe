package blockchain.ledger

import blockchain.*
import blockchain.consensus.*
import blockchain.codecs.given
import blockchain.models.*
import cats.implicits.*
import cats.effect.{Async, Resource}
import fs2.concurrent.Topic
import org.typelevel.log4cats.Logger
import org.typelevel.log4cats.slf4j.Slf4jLogger

import java.time.Instant

trait Mempool[F[_]]:
  def read: F[List[Transaction]]
  def add(transaction: Transaction): F[Unit]
  def changes: fs2.Stream[F, MempoolChange]

object Mempool:
  class State(var entries: List[Entry])
  object State:
    def default: State = new State(Nil)
  case class Entry(transaction: Transaction, addedAt: Instant)
  type BSS[F[_]] = BlockSourcedState[F, State]

  def make[F[_]: Async](
      bss: BSS[F],
      localChain: LocalChain[F],
      fetchHeader: FetchHeader[F],
      bodyValidation: BodyValidation[F],
      clock: Clock[F],
      saveTransaction: Transaction => F[Unit]
  ): Resource[F, Mempool[F] with BlockPacker[F]] =
    Resource
      .make(Topic[F, MempoolChange])(_.close.void)
      .map(mempoolChangesTopic =>
        new MempoolImpl[F](
          bss,
          localChain,
          fetchHeader,
          bodyValidation,
          clock,
          mempoolChangesTopic,
          saveTransaction
        )
      )

  def makeBSS[F[_]: Async](
      initialState: F[State],
      initialBlockId: F[BlockId],
      blockIdTree: BlockIdTree[F],
      onBlockChanged: BlockId => F[Unit],
      fetchBody: FetchBody[F],
      fetchTransaction: FetchTransaction[F]
  ): Resource[F, BSS[F]] =
    Resource
      .pure(new MempoolBSS[F](fetchBody, fetchTransaction))
      .flatMap(bssImpl =>
        BlockSourcedState.make(
          initialState,
          initialBlockId,
          bssImpl.applyBlock,
          bssImpl.unapplyBlock,
          blockIdTree,
          onBlockChanged
        )
      )

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
    mempoolChangesTopic: Topic[F, MempoolChange],
    saveTransaction: Transaction => F[Unit]
) extends Mempool[F]
    with BlockPacker[F]:

  private given logger: Logger[F] = Slf4jLogger.getLoggerFromName("Mempool")

  override def read: F[List[Transaction]] =
    localChain.currentHead
      .flatMap(
        bss
          .stateAt(_)
          .use(state =>
            retainValid(state.entries.map(_.transaction)).flatTap(updated =>
              Async[F].delay(state.entries = updated.flatMap(u => state.entries.find(_.transaction.id == u.id)))
            )
          )
      )

  override def add(transaction: Transaction): F[Unit] =
    localChain.currentHead
      .flatMap(headId =>
        bss
          .stateAt(headId)
          .use(s =>
            if (s.entries.exists(_.transaction.id == transaction.id))
              logger.info(show"Ignoring duplicate transaction id=${transaction.id}")
            else
              bodyValidation
                .validate(
                  FullBlockBody(s.entries.map(_.transaction) :+ transaction),
                  TransactionValidationContext(headId, 0, 0)
                )
                .leftMap(errors => new IllegalArgumentException(errors.head))
                .rethrowT >>
                saveTransaction(transaction) >>
                Async[F].delay(s.entries = s.entries :+ Mempool.Entry(transaction, Instant.now())) >>
                logger.info(show"Included transaction id=${transaction.id}")
          )
      )

  override def changes: fs2.Stream[F, MempoolChange] =
    mempoolChangesTopic.subscribeUnbounded

  override def streamed: fs2.Stream[F, FullBlockBody] =
    fs2.Stream
      .apply(())
      .merge(
        localChain.adoptions.void
          .merge(changes.void)
      )
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
            FullBlockBody(transactions :+ transaction),
            TransactionValidationContext(headId, head.height + 1, slot)
          )
          .fold(_ => transactions, _ => transactions :+ transaction)
      )
    } yield newTransactions

class MempoolBSS[F[_]: Async](fetchBody: FetchBody[F], fetchTransaction: FetchTransaction[F]):
  def applyBlock(state: Mempool.State, blockId: BlockId): F[Mempool.State] =
    fetchBody(blockId)
      .flatMap(body =>
        Async[F].delay(
          body.transactionIds.foreach(transactionId =>
            state.entries = state.entries.filterNot(_.transaction.id == transactionId)
          )
        )
      )
      .as(state)
  def unapplyBlock(state: Mempool.State, blockId: BlockId): F[Mempool.State] =
    fetchBody(blockId)
      .flatMap(_.transactionIds.traverse(fetchTransaction))
      .flatMap(transactions =>
        Async[F].delay(
          state.entries ++= transactions.filter(_.rewardParentBlockId.isEmpty).map(Mempool.Entry(_, Instant.now()))
        )
      )
      .as(state)
