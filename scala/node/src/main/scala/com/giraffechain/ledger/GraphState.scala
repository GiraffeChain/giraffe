package com.giraffechain.ledger

import com.giraffechain.*
import com.giraffechain.codecs.{*, given}
import com.giraffechain.models.*
import cats.effect.implicits.*
import cats.effect.{Async, Resource}
import cats.implicits.*
import com.google.protobuf.struct
import io.circe.Json

import java.sql.{Connection, PreparedStatement}

trait GraphState[F[_]] {

  def inEdges(
      parentBlockId: BlockId
  )(vertex: TransactionOutputReference): F[List[TransactionOutputReference]]

  def outEdges(
      parentBlockId: BlockId
  )(vertex: TransactionOutputReference): F[List[TransactionOutputReference]]

  def edges(
      parentBlockId: BlockId
  )(vertex: TransactionOutputReference): F[List[TransactionOutputReference]]

  def queryVertices(
      parentBlockId: BlockId
  )(label: String, whereClauses: Seq[WhereClause]): F[List[TransactionOutputReference]]

  def queryEdges(parentBlockId: BlockId)(
      label: String,
      a: Option[String],
      b: Option[String],
      whereClauses: Seq[WhereClause]
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

  override def inEdges(parentBlockId: BlockId)(
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

  override def outEdges(parentBlockId: BlockId)(
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

  override def edges(parentBlockId: BlockId)(
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

  override def queryVertices(
      parentBlockId: BlockId
  )(label: String, whereClauses: Seq[WhereClause]): F[List[TransactionOutputReference]] =
    bss
      .stateAt(parentBlockId)
      .use(connection =>
        Async[F].blocking {
          if (whereClauses.isEmpty) {
            val statement = connection.prepareStatement("SELECT id FROM vertices WHERE label = ?")
            statement.setString(1, label)
            List.unfold(statement.executeQuery())(resultSet =>
              Option.when(resultSet.next())(
                (resultSet.getString("id").decodeReference, resultSet)
              )
            )
          } else {
            val statement = connection.prepareStatement("SELECT id, data FROM vertices WHERE label = ?")
            statement.setString(1, label)
            Iterator
              .unfold(statement.executeQuery())(resultSet =>
                Option.when(resultSet.next())(
                  ((resultSet.getString("id").decodeReference, resultSet.getString("data")), resultSet)
                )
              )
              .flatMap((id, dataStr) =>
                io.circe.parser
                  .parse(dataStr)
                  .toOption
                  .flatMap(data =>
                    Option.when(
                      whereClauses.forall(whereClause =>
                        data.hcursor
                          .downField(whereClause.key)
                          .focus
                          .exists(value =>
                            whereClause.operand match {
                              case WhereClause.OperandEq => value == whereClause.value
                            }
                          )
                      )
                    )(id)
                  )
              )
              .toList
          }
        }
      )

  override def queryEdges(parentBlockId: BlockId)(
      label: String,
      a: Option[String],
      b: Option[String],
      whereClauses: Seq[WhereClause]
  ): F[List[TransactionOutputReference]] =
    bss
      .stateAt(parentBlockId)
      .use(connection =>
        Async[F].blocking {
          val abAndClauses = (a, b) match {
            case (Some(_), Some(_)) =>
              "AND a = ? AND b = ?"
            case (Some(_), None) =>
              "AND a = ?"
            case (None, Some(_)) =>
              "AND b = ?"
            case (None, None) =>
              ""
          }
          def applyABStatements(statement: PreparedStatement): Unit = {
            (a, b) match {
              case (Some(a), Some(b)) =>
                statement.setString(2, a)
                statement.setString(3, b)
              case (Some(a), None) =>
                statement.setString(2, a)
              case (None, Some(b)) =>
                statement.setString(2, b)
              case (None, None) =>
            }
          }
          if (whereClauses.isEmpty) {
            val statement = connection.prepareStatement(s"SELECT id FROM edges WHERE label = ?$abAndClauses")
            statement.setString(1, label)
            applyABStatements(statement)
            List.unfold(statement.executeQuery())(resultSet =>
              Option.when(resultSet.next())(
                (resultSet.getString("id").decodeReference, resultSet)
              )
            )
          } else {
            val statement = connection.prepareStatement(s"SELECT id FROM edges WHERE label = ?$abAndClauses")
            statement.setString(1, label)
            applyABStatements(statement)
            Iterator
              .unfold(statement.executeQuery())(resultSet =>
                Option.when(resultSet.next())(
                  ((resultSet.getString("id").decodeReference, resultSet.getString("data")), resultSet)
                )
              )
              .flatMap((id, dataStr) =>
                io.circe.parser
                  .parse(dataStr)
                  .toOption
                  .tupleLeft(id)
              )
              .flatMap((id, data) =>
                Option.when(
                  whereClauses.forall(whereClause =>
                    data.hcursor
                      .downField(whereClause.key)
                      .focus
                      .exists(value =>
                        whereClause.operand match {
                          case WhereClause.OperandEq => value == whereClause.value
                        }
                      )
                  )
                )(id)
              )
              .toList
          }
        }
      )

object GraphStateImpl:
  extension (ref: TransactionOutputReference) def encoded: String = show"${ref.transactionId.get}:${ref.index}"
  extension (encoded: String)
    def decodeReference: TransactionOutputReference = {
      val s = encoded.split(':')
      TransactionOutputReference(s(0).decodeTransactionId.some, s(1).toInt)
    }

  extension (s: struct.Struct)
    def encoded: String = json.noSpaces
    def json: Json =
      Json.obj(
        s.fields.map { case (k, v) =>
          k -> v.json
        }.toSeq*
      )

  extension (value: struct.Value)
    def json: Json =
      value.kind match {
        case struct.Value.Kind.NumberValue(v) => Json.fromBigDecimal(v)
        case struct.Value.Kind.StringValue(v) => Json.fromString(v)
        case struct.Value.Kind.BoolValue(v)   => Json.fromBoolean(v)
        case struct.Value.Kind.StructValue(v) => v.json
        case struct.Value.Kind.ListValue(v)   => Json.arr(v.values.map(_.json)*)
        case _                                => Json.Null
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
    initDb(connection).toResource >> BlockSourcedState.make[F, Connection](
      connection.pure[F],
      initialBlockId,
      applyBlock,
      unapplyBlock,
      blockIdTree,
      onBlockChanged
    )

  def initDb(connection: Connection): F[Unit] = Async[F].blocking {
    val statement = connection.createStatement()
    statement.execute(
      """
        |CREATE TABLE IF NOT EXISTS vertices (
        |  id VARCHAR(64) PRIMARY KEY,
        |  label VARCHAR(128) NOT NULL,
        |  data TEXT
        |)
        |""".stripMargin
    )
    statement.execute(
      """
        |CREATE TABLE IF NOT EXISTS edges (
        |  id VARCHAR(64) PRIMARY KEY,
        |  label VARCHAR(128) NOT NULL,
        |  data TEXT,
        |  a VARCHAR(64) NOT NULL,
        |  b VARCHAR(64) NOT NULL
        |)
        |""".stripMargin
    )
    statement.execute("CREATE INDEX IF NOT EXISTS vertices_label ON vertices (label)")
    statement.execute("CREATE INDEX IF NOT EXISTS edges_label ON edges (label)")
    statement.execute("CREATE INDEX IF NOT EXISTS edges_a ON edges (a)")
    statement.execute("CREATE INDEX IF NOT EXISTS edges_b ON edges (b)")
  }

  def applyBlock(
      connection: Connection,
      blockId: BlockId
  ): F[Connection] =
    applyBlockSteps(blockId).flatMap(executeSteps(connection)).as(connection)

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
                    output.graphEntry.map(_.entry).collect {
                      case GraphEntry.Entry.Vertex(_) =>
                        RemoveVertex(input.reference.encoded)
                      case GraphEntry.Entry.Edge(_) =>
                        RemoveEdge(input.reference.encoded)
                    }
                  )
                )
                .map(_.flatten),
              Async[F].delay(
                transaction.referencedOutputs.flatMap((ref, output) =>
                  output.graphEntry.map(_.entry).collect {
                    case GraphEntry.Entry.Vertex(v) =>
                      AddVertex(ref.encoded, v.label, v.data.map(_.encoded))
                    case GraphEntry.Entry.Edge(e) =>
                      val a = e.a.transactionId.fold(e.a.copy(transactionId = ref.transactionId))(_ => e.a)
                      val b = e.b.transactionId.fold(e.b.copy(transactionId = ref.transactionId))(_ => e.b)
                      AddEdge(ref.encoded, e.label, e.data.map(_.encoded), a.encoded, b.encoded)
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
    unapplyBlockSteps(blockId).flatMap(executeSteps(connection)).as(connection)

  private def unapplyBlockSteps(blockId: BlockId) =
    fetchBody(blockId)
      .map(_.transactionIds.reverse)
      .flatMap(
        _.traverse(transactionId =>
          fetchTransaction(transactionId).flatMap(transaction =>
            (
              Async[F].delay(
                transaction.referencedOutputs.reverse.flatMap((ref, output) =>
                  output.graphEntry.map(_.entry).collect {
                    case GraphEntry.Entry.Edge(_) =>
                      RemoveEdge(ref.encoded)
                    case GraphEntry.Entry.Vertex(_) =>
                      RemoveVertex(ref.encoded)
                  }
                )
              ),
              transaction.inputs.reverse
                .traverse(input =>
                  fetchTransactionOutput(input.reference).map(output =>
                    output.graphEntry.map(_.entry).collect {
                      case GraphEntry.Entry.Vertex(v) =>
                        AddVertex(input.reference.encoded, v.label, v.data.map(_.encoded))
                      case GraphEntry.Entry.Edge(e) =>
                        AddEdge(input.reference.encoded, e.label, e.data.map(_.encoded), e.a.encoded, e.b.encoded)
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
    if (steps.isEmpty) Async[F].unit
    else
      Async[F]
        .blocking {
          connection.setAutoCommit(false)
          steps.foreach {
            case RemoveVertex(id) =>
              val statement = connection.prepareStatement("DELETE FROM vertices WHERE id = ?")
              statement.setString(1, id)
              statement.execute()
              val statement2 = connection.prepareStatement("DELETE FROM edges WHERE a = ? OR b = ?")
              statement2.setString(1, id)
              statement2.setString(2, id)
              statement2.execute()
            case RemoveEdge(id) =>
              val statement = connection.prepareStatement("DELETE FROM edges WHERE id = ?")
              statement.setString(1, id)
              statement.execute()
            case AddVertex(id, label, data) =>
              val statement =
                connection.prepareStatement("INSERT INTO vertices (id, label, data) VALUES (?, ?, ?)")
              statement.setString(1, id)
              statement.setString(2, label)
              data.fold(statement.setNull(3, java.sql.Types.LONGVARCHAR))(statement.setString(3, _))
              statement.execute()
            case AddEdge(id, label, data, a, b) =>
              val statement =
                connection.prepareStatement("INSERT INTO edges (id, label, data, a, b) VALUES (?, ?, ?, ?, ?)")
              statement.setString(1, id)
              statement.setString(2, label)
              data.fold(statement.setNull(3, java.sql.Types.LONGVARCHAR))(statement.setString(3, _))
              statement.setString(4, a)
              statement.setString(5, b)
              statement.execute()
          }
          connection.commit()
        }
        .onError { case _ => Async[F].blocking(connection.rollback()) }

sealed abstract class GraphStateChange
case class RemoveVertex(id: String) extends GraphStateChange
case class RemoveEdge(id: String) extends GraphStateChange
case class AddVertex(id: String, label: String, data: Option[String]) extends GraphStateChange
case class AddEdge(id: String, label: String, data: Option[String], a: String, b: String) extends GraphStateChange

case class WhereClause(key: String, operand: WhereClause.Operand, value: Json)
object WhereClause:
  sealed abstract class Operand
  case object OperandEq extends Operand
