package blockchain

import blockchain.*
import blockchain.codecs.*
import blockchain.crypto.{Blake2b256, Blake2b512, Ed25519VRF}
import blockchain.models.*
import blockchain.utility.*
import com.google.protobuf.ByteString

import java.nio.charset.StandardCharsets

package object consensus:
  type Eta = Bytes
  type Rho = Bytes
  type RhoHash = Bytes

  case class VrfArgument(eta: Eta, slot: Long)

  private val TestStringByteArray = "TEST".getBytes(StandardCharsets.UTF_8)

  private val NonceStringByteArray = "NONCE".getBytes(StandardCharsets.UTF_8)

  def thresholdEvidence(threshold: Ratio)(using
      blake2b256: Blake2b256
  ): Bytes =
    blake2b256.hash(
      ByteString.copyFromUtf8(threshold.numerator.toString()),
      ByteString.copyFromUtf8(threshold.denominator.toString())
    )

  /** @param rho
    *   length = 64
    * @return
    *   length = 64
    */
  def rhoToRhoTestHash(rho: Bytes)(using blake2b512: Blake2b512): Bytes =
    blake2b512.hash(rho.toByteArray, TestStringByteArray)

  /** @param rho
    *   length = 64
    * @return
    *   length = 64
    */
  def rhoToRhoNonceHash(rho: Bytes)(using blake2b512: Blake2b512): Bytes =
    blake2b512.hash(rho.toByteArray, NonceStringByteArray)

  extension (header: BlockHeader)
    def rho: Ed25519VRF ?=> Rho =
      ByteString.copyFrom(
        summon[Ed25519VRF].proofToHash(
          header.stakerCertificate.vrfSignature.decodeBase58.toByteArray
        )
      )
    def unsigned: UnsignedBlockHeader =
      UnsignedBlockHeader(
        header.parentHeaderId,
        header.parentSlot,
        header.txRoot,
        header.timestamp,
        header.height,
        header.slot,
        UnsignedBlockHeader.PartialStakerCertificate(header.stakerCertificate),
        header.account
      )

  case class UnsignedBlockHeader(
      parentHeaderId: BlockId,
      parentSlot: Slot,
      txRoot: String,
      timestamp: Timestamp,
      height: Height,
      slot: Slot,
      partialStakerCertificate: UnsignedBlockHeader.PartialStakerCertificate,
      account: TransactionOutputReference
  )

  object UnsignedBlockHeader:
    case class PartialStakerCertificate(
        vrfSignature: String,
        vrfVK: String,
        thresholdEvidence: String,
        eta: String
    )
    object PartialStakerCertificate:
      def apply(stakerCertificate: StakerCertificate): PartialStakerCertificate = PartialStakerCertificate(
        stakerCertificate.vrfSignature,
        stakerCertificate.vrfVK,
        stakerCertificate.thresholdEvidence,
        stakerCertificate.eta
      )
