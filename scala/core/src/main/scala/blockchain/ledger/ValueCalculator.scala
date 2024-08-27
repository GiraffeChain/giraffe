package blockchain.ledger

import blockchain.models.{GraphEntry, TransactionOutput}
import cats.effect.{Resource, Sync}
import cats.implicits.*
import com.google.protobuf.struct

trait ValueCalculator[F[_]] {
  def requiredMinimumQuantity(output: TransactionOutput): F[Long]
}

class ValueCalculatorImpl[F[_]: Sync] extends ValueCalculator[F] {
  // TODO: Add these numbers to ProtocolSettings
  def requiredMinimumQuantity(output: TransactionOutput): F[Long] =
    List(
      Sync[F].delay(100L), // dust prevention
      Sync[F].delay(output.account.as(50L).getOrElse(0L)), // association with an existing staking account
      Sync[F].delay(output.value.accountRegistration.as(1000L).getOrElse(0L)), // new staker registration
      Sync[F].delay(output.value.graphEntry.fold(0L)(graphEntryMinimumQuantity)) // graph data
    ).sequence.map(_.sum)

  def graphEntryMinimumQuantity(graphEntry: GraphEntry): Long =
    graphEntry.entry match {
      case GraphEntry.Entry.Vertex(v) => v.label.length.toLong * 10 + v.data.fold(0L)(protoStructMinimumQuantity)
      case GraphEntry.Entry.Edge(e)   => e.label.length.toLong * 10 + 100L + e.data.fold(0L)(protoStructMinimumQuantity)
      case _                          => 0L
    }

  def protoValueMinimumQuantity(value: struct.Value): Long =
    value.kind match {
      case struct.Value.Kind.StringValue(v) => v.length.toLong * 10
      case struct.Value.Kind.NumberValue(v) => v.toString.length.toLong * 10
      case struct.Value.Kind.BoolValue(_)   => 10L
      case struct.Value.Kind.ListValue(v)   => v.values.map(protoValueMinimumQuantity).sum
      case struct.Value.Kind.StructValue(v) => protoStructMinimumQuantity(v)
      case _                                => 10L
    }

  def protoStructMinimumQuantity(value: struct.Struct): Long =
    value.fields.toList.map(f => f._1.length + protoValueMinimumQuantity(f._2)).sum
}

object ValueCalculatorImpl:
  def make[F[_]: Sync]: Resource[F, ValueCalculator[F]] =
    Resource.pure(new ValueCalculatorImpl[F])
