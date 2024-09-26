package com.giraffechain

import cats.data.OptionT
import cats.implicits.*
import cats.{Applicative, Monad}
import com.giraffechain.codecs.{*, given}
import com.giraffechain.crypto.Blake2b256
import com.giraffechain.models.*
import com.google.protobuf.ByteString

package object ledger {

  extension (transaction: Transaction)
    def dependencies: Set[TransactionOutputReference] =
      (transaction.inputs.map(_.reference) ++
        transaction.outputs.flatMap(_.account) ++
        transaction.outputs
          .flatMap(_.graphEntry.flatMap(_.entry.edge))
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
            output.graphEntry
              .flatMap(_.entry.edge)
              .fold(Set.empty[TransactionOutputReference])(edge => Set(edge.a, edge.b))
              .toList
              .traverse(fetchTransactionOutputOrLocal(fetchTransactionOutput, transaction))
              .map(_.flatMap(_.graphEntry).flatMap(_.entry.vertex).flatMap(_.edgeLockAddress))
              .flatMap(graphLockAddresses =>
                OptionT(output.account.traverse(fetchTransactionOutputOrLocal(fetchTransactionOutput, transaction)))
                  .subflatMap(_.accountRegistration.map(_.associationLock))
                  .fold(graphLockAddresses)(graphLockAddresses :+ _)
              )
          )
          .map(_.flatten.toSet)
      } yield inputResults ++ outputResults

    def reward[F[_]: Monad](fetchTransactionOutput: FetchTransactionOutput[F]): F[Long] =
      (
        transaction.inputs.foldMapM(i => fetchTransactionOutput(i.reference).map(_.quantity)),
        transaction.outputs.foldMap(_.quantity).pure[F]
      ).mapN(_ - _)

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
