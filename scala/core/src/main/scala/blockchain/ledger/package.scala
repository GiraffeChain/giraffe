package blockchain

import blockchain.models.*
import blockchain.codecs.given
import blockchain.crypto.Blake2b256
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

  extension (transactionIds: Seq[TransactionId])
    def txRoot(parentTxRoot: Bytes): Bytes =
      ByteString.copyFrom(
        new Blake2b256().hash(
          (parentTxRoot +: transactionIds.map(_.value)).map(_.toByteArray)*
        )
      )
}
