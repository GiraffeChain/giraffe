package blockchain

import blockchain.codecs.{*, given}
import blockchain.consensus.Eta
import blockchain.crypto.Blake2b256
import blockchain.ledger.*
import blockchain.models.*
import cats.effect.Sync
import com.google.common.primitives.Longs
import com.google.protobuf.ByteString
import scodec.bits.ByteVector

object Genesis:
  private val byteStringZero32 = "11111111111111111111111111111111"
  private val byteStringZero64 = "1111111111111111111111111111111111111111111111111111111111111111"
  private val byteStringZero80 = "11111111111111111111111111111111111111111111111111111111111111111111111111111111"
  val Height: Long = 1
  val Slot: Long = 0
  val ParentId: BlockId = BlockId(byteStringZero32)
  val ParentSlot: Slot = -1L
  val StakingAccount: TransactionOutputReference = TransactionOutputReference(
    TransactionId(byteStringZero32)
  )

  def vrfCertificate(eta: Eta): EligibilityCertificate = EligibilityCertificate(
    byteStringZero80,
    byteStringZero32,
    byteStringZero32,
    eta = ByteVector(eta.toByteArray).toBase58
  )

  val kesCertificate: OperationalCertificate = OperationalCertificate(
    VerificationKeyKesProduct(byteStringZero32, 0),
    SignatureKesProduct(
      SignatureKesSum(
        byteStringZero32,
        byteStringZero64,
        Vector.empty
      ),
      SignatureKesSum(
        byteStringZero32,
        byteStringZero64,
        Vector.empty
      ),
      byteStringZero32
    ),
    byteStringZero32,
    byteStringZero64
  )

  def init[F[_]: Sync](timestamp: Timestamp, transactions: List[Transaction]): F[FullBlock] =
    Sync[F].delay {

      val eta: Eta =
        ByteString.copyFrom(
          new Blake2b256().hash(
            Longs.toByteArray(timestamp) +:
              transactions.map(_.id.value.decodeBase58.toByteArray)*
          )
        )

      val header =
        BlockHeader(
          parentHeaderId = ParentId,
          parentSlot = ParentSlot,
          txRoot =
            ByteVector(transactions.map(_.id).txRoot(byteStringZero32.decodeBase58.toByteArray).toByteArray).toBase58,
          timestamp = timestamp,
          height = Height,
          slot = Slot,
          eligibilityCertificate = vrfCertificate(eta),
          operationalCertificate = kesCertificate,
          metadata = "",
          account = StakingAccount
        ).withEmbeddedId
      FullBlock(header, FullBlockBody(transactions))
    }
