package blockchain.codecs

import blockchain.models.*
import cats.Show
import com.google.protobuf.ByteString
import scodec.bits.ByteVector
import cats.implicits.*

trait ShowInstances {
  given showByteString: Show[ByteString] = bytes =>
    ByteVector.apply(bytes.asReadOnlyByteBuffer()).toBase58
  given showBlockId: Show[BlockId] = blockId => show"b_${blockId.value.show}"
  given showTransactionId: Show[TransactionId] = transactionId =>
    show"t_${transactionId.value.show}"
  given showSlotId: Show[SlotId] = slotId =>
    show"${slotId.blockId}@${slotId.slot}"
  given showTransactionOutputReference: Show[TransactionOutputReference] =
    reference => show"${reference.transactionId}#${reference.index}"
}
