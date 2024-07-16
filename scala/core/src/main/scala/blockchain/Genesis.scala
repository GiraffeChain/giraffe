package blockchain

import blockchain.codecs.{*, given}
import blockchain.consensus.Eta
import blockchain.crypto.{Blake2b256, CryptoResources}
import blockchain.ledger.*
import blockchain.models.*
import blockchain.utility.BlockLoading
import cats.effect.std.Random
import cats.effect.{Async, Sync}
import com.google.common.primitives.Longs
import com.google.protobuf.ByteString
import fs2.io.file.{Files, Path}
import fs2.io.net.Network
import org.http4s.client.middleware.FollowRedirect
import org.http4s.ember.client.EmberClientBuilder
import scodec.bits.ByteVector

object Genesis:
  private val byteStringZero32 = "11111111111111111111111111111111"
  private val byteStringZero64 = "1111111111111111111111111111111111111111111111111111111111111111"
  private val byteStringZero80 = "11111111111111111111111111111111111111111111111111111111111111111111111111111111"
  val Height: Long = 1
  val Slot: Long = 0
  val ParentId: BlockId = BlockId(byteStringZero32)
  val ParentSlot: Slot = -1L
  val ParentTxRoot: String = byteStringZero32
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
            ByteVector(transactions.map(_.id).txRoot(ParentTxRoot.decodeBase58.toByteArray).toByteArray).toBase58,
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

  def parse[F[_]: Async: Files: Random: CryptoResources](arg: String): F[FullBlock] =
    Sync[F].defer {
      if (arg.startsWith("testnet:")) {
        Testnet.init(Path("/tmp/blockchain-genesis"), arg.substring(8))
      } else {
        HeaderToBodyValidation
          .staticParentTxRoot(ParentTxRoot.decodeBase58.toByteArray)
          .use(txRootValidation =>
            if (arg.startsWith("http://") || arg.startsWith("https://")) {
              implicit val networkF: Network[F] = Network.forAsync
              val fileName = arg.substring(arg.lastIndexOf('/')) + 1
              // TODO: Use effect
              assert(fileName.endsWith(".pbuf"))
              val blockId = fileName.dropRight(5).decodeBlockId
              EmberClientBuilder
                .default[F]
                .build
                .map(FollowRedirect(10))
                .map(client => client.expect[Array[Byte]](arg))
                .use(BlockLoading.load(_)(txRootValidation)(blockId))
            } else {
              val fileName = arg.lastIndexOf('/') match {
                case -1 => arg
                case i  => arg.substring(i + 1)
              }
              // TODO: Use effect
              assert(fileName.endsWith(".pbuf"))
              val blockId = fileName.dropRight(5).decodeBlockId
              BlockLoading
                .load(Files.forAsync[F].readAll(Path(arg)).compile.to(Array))(
                  txRootValidation
                )(blockId)
            }
          )
      }
    }
