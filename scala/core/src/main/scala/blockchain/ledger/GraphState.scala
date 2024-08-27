package blockchain.ledger

import blockchain.*
import blockchain.codecs.{*, given}
import blockchain.models.*
import cats.effect.{Async, Resource}
import cats.implicits.*

import java.sql.Connection

trait GraphState[F[_]] {

  def inEdges(
      parentBlockId: BlockId,
      vertex: TransactionOutputReference
  ): F[List[TransactionOutputReference]]

  def outEdges(
      parentBlockId: BlockId,
      vertex: TransactionOutputReference
  ): F[List[TransactionOutputReference]]

  def edges(
      parentBlockId: BlockId,
      vertex: TransactionOutputReference
  ): F[List[TransactionOutputReference]]

}

object GraphState:
  type BSS[F[_]] = BlockSourcedState[F, Connection]

  def make[F[_]: Async](bss: BSS[F]): Resource[F, GraphState[F]] =
    Resource.pure(new GraphStateImpl[F](bss))

  def makeBSS[F[_]: Async](
      connection: Connection,
      initialBlockId: F[BlockId],
      blockIdTree: BlockIdTree[F],
      onBlockChanged: BlockId => F[Unit],
      fetchBody: FetchBody[F],
      fetchTransaction: FetchTransaction[F],
      fetchTransactionOutput: FetchTransactionOutput[F]
  ): Resource[F, BSS[F]] =
    new GraphStateBSSImpl[F](fetchBody, fetchTransaction, fetchTransactionOutput)
      .makeBss(connection, initialBlockId, blockIdTree, onBlockChanged)

class GraphStateImpl[F[_]: Async](bss: GraphState.BSS[F]) extends GraphState[F]:
  import GraphStateImpl.*

  override def inEdges(
      parentBlockId: BlockId,
      vertex: TransactionOutputReference
  ): F[List[TransactionOutputReference]] =
    bss
      .stateAt(parentBlockId)
      .use(connection =>
        Async[F].blocking {
          val statement = connection.prepareStatement("SELECT id FROM edges WHERE b = ?")
          statement.setString(1, vertex.encoded)

          List.unfold(statement.executeQuery())(resultSet =>
            Option.when(resultSet.next())(
              (resultSet.getString("id").decodeReference, resultSet)
            )
          )
        }
      )

  override def outEdges(
      parentBlockId: BlockId,
      vertex: TransactionOutputReference
  ): F[List[TransactionOutputReference]] =
    bss
      .stateAt(parentBlockId)
      .use(connection =>
        Async[F].blocking {
          val statement = connection.prepareStatement("SELECT id FROM edges WHERE a = ?")
          statement.setString(1, vertex.encoded)

          List.unfold(statement.executeQuery())(resultSet =>
            Option.when(resultSet.next())(
              (resultSet.getString("id").decodeReference, resultSet)
            )
          )
        }
      )

  override def edges(
      parentBlockId: BlockId,
      vertex: TransactionOutputReference
  ): F[List[TransactionOutputReference]] =
    bss
      .stateAt(parentBlockId)
      .use(connection =>
        Async[F].blocking {
          val encodedVertex = vertex.encoded
          val statement = connection.prepareStatement("SELECT id FROM edges WHERE a = ? OR b = ?")
          statement.setString(1, encodedVertex)
          statement.setString(2, encodedVertex)

          List.unfold(statement.executeQuery())(resultSet =>
            Option.when(resultSet.next())(
              (resultSet.getString("id").decodeReference, resultSet)
            )
          )
        }
      )

object GraphStateImpl:
  extension (ref: TransactionOutputReference) def encoded: String = show"${ref.transactionId}:${ref.index}"
  extension (encoded: String)
    def decodeReference: TransactionOutputReference = {
      val s = encoded.split(':')
      TransactionOutputReference(s(0).decodeTransactionId, s(1).toInt)
    }

class GraphStateBSSImpl[F[_]: Async](
    fetchBody: FetchBody[F],
    fetchTransaction: FetchTransaction[F],
    fetchTransactionOutput: FetchTransactionOutput[F]
):
  import GraphStateImpl.*
  def makeBss(
      connection: Connection,
      initialBlockId: F[BlockId],
      blockIdTree: BlockIdTree[F],
      onBlockChanged: BlockId => F[Unit]
  ): Resource[F, GraphState.BSS[F]] =
    BlockSourcedState.make[F, Connection](
      connection.pure[F],
      initialBlockId,
      applyBlock,
      unapplyBlock,
      blockIdTree,
      onBlockChanged
    )

  def applyBlock(
      connection: Connection,
      blockId: BlockId
  ): F[Connection] =
    applyBlockSteps(blockId).flatMap(executeSteps(connection))

  private def applyBlockSteps(blockId: BlockId) =
    fetchBody(blockId)
      .map(_.transactionIds)
      .flatMap(
        _.traverse(transactionId =>
          fetchTransaction(transactionId).flatMap(transaction =>
            (
              transaction.inputs
                .traverse(input =>
                  fetchTransactionOutput(input.reference).map(output =>
                    output.value.graphEntry.map(_.entry).collect {
                      case GraphEntry.Entry.Vertex(_) => RemoveNode(input.reference.encoded)
                      case GraphEntry.Entry.Edge(_)   => RemoveEdge(input.reference.encoded)
                    }
                  )
                )
                .map(_.flatten),
              Async[F].delay(
                transaction.referencedOutputs.flatMap((ref, output) =>
                  output.value.graphEntry.map(_.entry).collect { case GraphEntry.Entry.Edge(e) =>
                    AddEdge(ref.encoded, e.a.encoded, e.b.encoded)
                  }
                )
              )
            ).mapN(_ ++ _)
          )
        )
          .map(_.flatten)
      )

  def unapplyBlock(
      connection: Connection,
      blockId: BlockId
  ): F[Connection] =
    unapplyBlockSteps(blockId).flatMap(executeSteps(connection))

  private def unapplyBlockSteps(blockId: BlockId) =
    fetchBody(blockId)
      .map(_.transactionIds.reverse)
      .flatMap(
        _.traverse(transactionId =>
          fetchTransaction(transactionId).flatMap(transaction =>
            (
              Async[F].delay(
                transaction.referencedOutputs.reverse.flatMap((ref, output) =>
                  output.value.graphEntry.map(_.entry).collect {
                    case GraphEntry.Entry.Edge(e) =>
                      RemoveEdge(ref.encoded)
                    case GraphEntry.Entry.Vertex(_) => RemoveNode(ref.encoded)
                  }
                )
              ),
              transaction.inputs.reverse
                .traverse(input =>
                  fetchTransactionOutput(input.reference).map(output =>
                    output.value.graphEntry.map(_.entry).collect { case GraphEntry.Entry.Edge(e) =>
                      AddEdge(input.reference.encoded, e.a.encoded, e.b.encoded)
                    }
                  )
                )
                .map(_.flatten)
            ).mapN(_ ++ _)
          )
        )
          .map(_.flatten)
      )

  private def executeSteps(connection: Connection)(steps: Iterable[GraphStateChange]) =
    Async[F].blocking {
      val statement = connection.createStatement()
      steps.foreach {
        case RemoveNode(id)    => statement.addBatch(s"DELETE FROM edges WHERE a = '$id' OR b = '$id'")
        case RemoveEdge(id)    => statement.addBatch(s"DELETE FROM edges WHERE id = '$id'")
        case AddEdge(id, a, b) => statement.addBatch(s"INSERT INTO edges (id, a, b) VALUES ('$id', '$a', '$b')")
      }
      statement.executeBatch()
      connection
    }

sealed abstract class GraphStateChange
case class RemoveNode(id: String) extends GraphStateChange
case class RemoveEdge(id: String) extends GraphStateChange
case class AddEdge(id: String, a: String, b: String) extends GraphStateChange
