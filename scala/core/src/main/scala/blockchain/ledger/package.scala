package blockchain

import blockchain.codecs.{*, given}
import blockchain.crypto.Blake2b256
import blockchain.models.*
import cats.data.OptionT
import cats.implicits.*
import cats.{Applicative, Monad}
import com.google.protobuf.ByteString

package object ledger {

  extension (transaction: Transaction)
    def dependencies: Set[TransactionOutputReference] =
      (transaction.inputs.map(_.reference) ++
        transaction.outputs.flatMap(_.account) ++
        transaction.outputs
          .flatMap(_.value.graphEntry.flatMap(_.entry.edge))
          .flatMap(edge => List(edge.a, edge.b))).filter(_.transactionId.nonEmpty).toSet

    def referencedOutputs: Seq[(TransactionOutputReference, TransactionOutput)] = {
      val someTransactionId = transaction.id.some
      transaction.outputs.zipWithIndex.map((out, index) => TransactionOutputReference(someTransactionId, index) -> out)
    }

    def requiredWitnesses[F[_]: Monad](fetchTransactionOutput: FetchTransactionOutput[F]): F[Set[LockAddress]] =
      for {
        inputResults <- transaction.inputs
          .traverse(input => fetchTransactionOutput(input.reference).map(_.lockAddress))
          .map(_.toSet)
        outputResults <- transaction.outputs
          .traverse(output =>
            output.value.graphEntry
              .flatMap(_.entry.edge)
              .fold(Set.empty[TransactionOutputReference])(edge => Set(edge.a, edge.b))
              .toList
              .traverse(fetchTransactionOutputOrLocal(fetchTransactionOutput, transaction))
              .map(_.flatMap(_.value.graphEntry).flatMap(_.entry.vertex).flatMap(_.edgeLockAddress))
              .flatMap(graphLockAddresses =>
                OptionT(output.account.traverse(fetchTransactionOutputOrLocal(fetchTransactionOutput, transaction)))
                  .subflatMap(_.value.accountRegistration.map(_.associationLock))
                  .fold(graphLockAddresses)(graphLockAddresses :+ _)
              )
          )
          .map(_.flatten.toSet)
      } yield inputResults ++ outputResults

    def reward: Long =
      transaction.inputs.foldMap(_.value.quantity) - transaction.outputs.foldMap(_.value.quantity)

    def fee: Long =
      100 // TODO

  extension (transactionIds: Seq[TransactionId])
    def txRoot(parentTxRoot: Bytes): Bytes =
      ByteString.copyFrom(
        new Blake2b256().hash(
          (parentTxRoot +: transactionIds.map(_.value.decodeBase58.toByteArray))*
        )
      )

  extension (reference: TransactionOutputReference)
    def withoutSelfReference(id: TransactionId): TransactionOutputReference =
      reference.transactionId match {
        case Some(_) => reference
        case _       => reference.copy(transactionId = id.some)
      }

  def fetchTransactionOutputOrLocal[F[_]: Applicative](
      fetchTransactionOutput: FetchTransactionOutput[F],
      local: Transaction
  )(reference: TransactionOutputReference): F[TransactionOutput] =
    reference.transactionId.fold(local.outputs(reference.index).pure[F])(_ => fetchTransactionOutput(reference))
}
