package blockchain

import blockchain.codecs.given
import blockchain.consensus.Eta
import blockchain.crypto.Blake2b256
import blockchain.ledger.*
import blockchain.models.*
import cats.effect.Sync
import com.google.common.primitives.Longs
import com.google.protobuf.ByteString

object Genesis:
  private val byteStringZero32 = ByteString.copyFrom(Array.fill[Byte](32)(0))
  val Height: Long = 1
  val Slot: Long = 0
  val ParentId: BlockId = BlockId(byteStringZero32)
  val ParentSlot: Slot = -1L
  val StakingAccount: TransactionOutputReference = TransactionOutputReference(
    TransactionId(byteStringZero32)
  )

  def vrfCertificate(eta: Eta): EligibilityCertificate = EligibilityCertificate(
    ByteString.copyFrom(Array.fill[Byte](80)(0)),
    byteStringZero32,
    byteStringZero32,
    eta = eta
  )

  val kesCertificate: OperationalCertificate = OperationalCertificate(
    VerificationKeyKesProduct(byteStringZero32, 0),
    SignatureKesProduct(
      SignatureKesSum(
        byteStringZero32,
        ByteString.copyFrom(Array.fill[Byte](64)(0)),
        Vector.empty
      ),
      SignatureKesSum(
        byteStringZero32,
        ByteString.copyFrom(Array.fill[Byte](64)(0)),
        Vector.empty
      ),
      byteStringZero32
    ),
    byteStringZero32,
    ByteString.copyFrom(Array.fill[Byte](64)(0))
  )

  def init[F[_]: Sync](timestamp: Timestamp, transactions: List[Transaction]): F[FullBlock] =
    Sync[F].delay {

      val eta: Eta =
        ByteString.copyFrom(
          new Blake2b256().hash(
            Longs.toByteArray(timestamp) +:
              transactions.map(_.id.value.toByteArray)*
          )
        )

      val header =
        BlockHeader(
          parentHeaderId = ParentId,
          parentSlot = ParentSlot,
          txRoot = transactions.map(_.id).txRoot(byteStringZero32),
          timestamp = timestamp,
          height = Height,
          slot = Slot,
          eligibilityCertificate = vrfCertificate(eta),
          operationalCertificate = kesCertificate,
          metadata = ByteString.EMPTY,
          account = StakingAccount
        ).withEmbeddedId
      FullBlock(header, FullBlockBody(transactions))
    }
