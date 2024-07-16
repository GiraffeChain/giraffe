package blockchain

import blockchain.models.*
import blockchain.codecs.{*, given}
import blockchain.crypto.Blake2b256
import cats.Monad
import cats.data.OptionT
import cats.implicits.*
import com.google.protobuf.ByteString

package object ledger {

  extension (transaction: Transaction)
    def dependencies: Set[TransactionOutputReference] =
      (transaction.inputs.map(_.reference) ++
        transaction.outputs.flatMap(_.account) ++
        transaction.outputs
          .flatMap(_.value.graphEntry.flatMap(_.entry.edge))
          .flatMap(edge => List(edge.a, edge.b))).toSet

    def referencedOutputs: Seq[(TransactionOutputReference, TransactionOutput)] =
      transaction.outputs.zipWithIndex.map((out, index) => TransactionOutputReference(transaction.id, index) -> out)

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
              .traverse(fetchTransactionOutput)
              .map(_.flatMap(_.value.graphEntry).flatMap(_.entry.vertex).flatMap(_.edgeLockAddress))
              .flatMap(graphLockAddresses =>
                OptionT(output.account.traverse(fetchTransactionOutput))
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
}
