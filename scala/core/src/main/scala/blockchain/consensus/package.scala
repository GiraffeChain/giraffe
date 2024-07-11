package blockchain

import blockchain.*
import blockchain.crypto.{Blake2b256, Blake2b512, Ed25519VRF}
import blockchain.models.*
import blockchain.codecs.given
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
      threshold.numerator.toString().immutableBytes,
      threshold.denominator.toString().immutableBytes
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
          header.eligibilityCertificate.vrfSig.toByteArray
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
        header.eligibilityCertificate,
        UnsignedBlockHeader.PartialOperationalCertificate(
          header.operationalCertificate.parentVK,
          header.operationalCertificate.parentSignature,
          header.operationalCertificate.childVK
        ),
        header.metadata,
        header.account
      )

  case class UnsignedBlockHeader(
      parentHeaderId: BlockId,
      parentSlot: Slot,
      txRoot: Bytes,
      timestamp: Timestamp,
      height: Height,
      slot: Slot,
      eligibilityCertificate: EligibilityCertificate,
      partialOperationalCertificate: UnsignedBlockHeader.PartialOperationalCertificate,
      metadata: Bytes,
      account: TransactionOutputReference
  )

  object UnsignedBlockHeader:
    case class PartialOperationalCertificate(
        parentVK: VerificationKeyKesProduct,
        parentSignature: SignatureKesProduct,
        childVK: Bytes
    )
