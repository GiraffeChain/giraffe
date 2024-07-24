package blockchain.codecs

import blockchain.models.*
import cats.Show
import com.google.protobuf.ByteString
import scodec.bits.ByteVector
import cats.implicits.*

trait ShowInstances {
  given showByteString: Show[ByteString] = bytes => ByteVector(bytes.toByteArray).toBase58
  given showBlockId: Show[BlockId] = blockId => show"b_${blockId.value.show}"
  given showTransactionId: Show[TransactionId] = transactionId => show"t_${transactionId.value.show}"
  given showLockAddress: Show[LockAddress] = address => show"a_${address.value.show}"
  given showSlotId: Show[SlotId] = slotId => show"${slotId.blockId}@${slotId.slot}"
  given showTransactionOutputReference: Show[TransactionOutputReference] =
    reference => show"${reference.transactionId}#${reference.index}"
  given showPeerId: Show[PeerId] =
    peerId => show"p_${peerId.value.substring(0, 8)}"

  extension (b: BlockId$)
    def fromShow(shown: String): BlockId = {
      val s = if (shown.startsWith("b_")) shown.substring(2) else shown
      BlockId(s)
    }

  extension (t: TransactionId$)
    def fromShow(shown: String): TransactionId = {
      val s = if (shown.startsWith("t_")) shown.substring(2) else shown
      TransactionId(s)
    }

  extension (a: LockAddress$)
    def fromShow(shown: String): LockAddress = {
      val s = if (shown.startsWith("a_")) shown.substring(2) else shown
      LockAddress(s)
    }
}
