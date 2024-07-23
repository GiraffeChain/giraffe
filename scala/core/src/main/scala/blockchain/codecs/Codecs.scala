package blockchain.codecs

import blockchain.Bytes
import blockchain.consensus.UnsignedBlockHeader.PartialOperationalCertificate
import blockchain.consensus.{UnsignedBlockHeader, VrfArgument}
import blockchain.crypto.Blake2b256
import blockchain.models.*
import cats.Monoid
import cats.implicits.*
import com.google.common.primitives.{Ints, Longs}
import com.google.protobuf
import com.google.protobuf.{ByteString, struct}
import scodec.bits.{BitVector, ByteVector}

import java.nio.charset.StandardCharsets

trait Codecs {

  import Codecs.*

  given structValueImmutableBytes: ImmutableBytes[struct.Value] with
    extension (value: struct.Value)
      def immutableBytes: Bytes =
        value.kind match {
          case struct.Value.Kind.Empty        => ZeroBS
          case struct.Value.Kind.NullValue(_) => ZeroBS
          case struct.Value.Kind.NumberValue(num) =>
            ByteString.copyFromUtf8(num.toString) // TODO
          case struct.Value.Kind.StringValue(string) =>
            ByteString.copyFromUtf8(string)
          case struct.Value.Kind.BoolValue(bool) =>
            bool.immutableBytes
          case struct.Value.Kind.StructValue(str) =>
            str.immutableBytes
          case struct.Value.Kind.ListValue(lv) =>
            lv.values.immutableBytes
        }

  given ImmutableBytes[Long] with
    extension (long: Long) def immutableBytes: Bytes = ByteString.copyFrom(Longs.toByteArray(long))

  given ImmutableBytes[Int] with
    extension (int: Int) def immutableBytes: Bytes = ByteString.copyFrom(Ints.toByteArray(int))

//  given ImmutableBytes[Double] with
//    extension (double: Double)
//      def immutableBytes: Bytes =
//        double.toString.immutableBytes // TODO precision

  given ImmutableBytes[Boolean] with
    extension (bool: Boolean) def immutableBytes: Bytes = if (bool) OneBS else ZeroBS

  extension (s: String)
    def decodeBase58: Bytes = ByteString.copyFrom(ByteVector.fromValidBase58(s).toArray)
    def decodeBlockId: BlockId = BlockId(if (s.startsWith("b_")) s.substring(2) else s)
    def decodeTransactionId: TransactionId = TransactionId(if (s.startsWith("t_")) s.substring(2) else s)
    def decodeLockAddress: LockAddress = LockAddress(if (s.startsWith("a_")) s.substring(2) else s)

  given ImmutableBytes[ByteString] with
    extension (b: ByteString)
      def immutableBytes: Bytes = b
      def base58: String = ByteVector(b.toByteArray).toBase58

  given ImmutableBytes[BlockHeader] with
    extension (header: BlockHeader)
      def id: BlockId =
        header.headerId.getOrElse(computedId)
      def computedId: BlockId =
        BlockId(
          ByteVector(
            new Blake2b256().hash(immutableBytes.toByteArray)
          ).toBase58
        )
      def withEmbeddedId: BlockHeader =
        header.copy(headerId = computedId.some)
      def immutableBytes: Bytes =
        header.parentHeaderId.immutableBytes
          .concat(header.parentSlot.immutableBytes)
          .concat(header.txRoot.decodeBase58)
          .concat(header.timestamp.immutableBytes)
          .concat(header.height.immutableBytes)
          .concat(header.slot.immutableBytes)
          .concat(header.eligibilityCertificate.immutableBytes)
          .concat(header.operationalCertificate.immutableBytes)
          .concat(header.metadata.decodeBase58)
          .concat(header.account.immutableBytes)

  given SignableBytes[UnsignedBlockHeader] with
    extension (header: UnsignedBlockHeader)
      def signableBytes: Bytes =
        header.parentHeaderId.immutableBytes
          .concat(header.parentSlot.immutableBytes)
          .concat(header.txRoot.decodeBase58)
          .concat(header.timestamp.immutableBytes)
          .concat(header.height.immutableBytes)
          .concat(header.slot.immutableBytes)
          .concat(header.eligibilityCertificate.immutableBytes)
          .concat(header.partialOperationalCertificate.immutableBytes)
          .concat(header.metadata.decodeBase58)
          .concat(header.account.immutableBytes)

  given ImmutableBytes[EligibilityCertificate] with
    extension (certificate: EligibilityCertificate)
      def immutableBytes: Bytes =
        certificate.vrfSig.decodeBase58.immutableBytes
          .concat(certificate.vrfVK.decodeBase58.immutableBytes)
          .concat(certificate.thresholdEvidence.decodeBase58.immutableBytes)
          .concat(certificate.eta.decodeBase58.immutableBytes)

  given ImmutableBytes[OperationalCertificate] with
    extension (certificate: OperationalCertificate)
      def immutableBytes: Bytes =
        certificate.parentVK.immutableBytes
          .concat(certificate.parentSignature.immutableBytes)
          .concat(certificate.childVK.decodeBase58.immutableBytes)
          .concat(certificate.childSignature.decodeBase58.immutableBytes)

  given ImmutableBytes[PartialOperationalCertificate] with
    extension (certificate: PartialOperationalCertificate)
      def immutableBytes: Bytes =
        certificate.parentVK.immutableBytes
          .concat(certificate.parentSignature.immutableBytes)
          .concat(certificate.childVK.decodeBase58.immutableBytes)

  given ImmutableBytes[VerificationKeyKesProduct] with
    extension (vk: VerificationKeyKesProduct)
      def immutableBytes: Bytes = vk.value.decodeBase58.immutableBytes.concat(vk.step.immutableBytes)

  given [T: ImmutableBytes]: ImmutableBytes[Seq[T]] with
    extension (iterable: Seq[T])
      def immutableBytes: Bytes =
        iterable.foldLeft(iterable.size.immutableBytes)((res, t) => res.concat(t.immutableBytes))

  given [T: ImmutableBytes]: ImmutableBytes[Option[T]] with
    extension (o: Option[T])
      def immutableBytes: Bytes =
        o.fold(ZeroBS)(v => OneBS.concat(v.immutableBytes))

  given ImmutableBytes[SignatureKesSum] with
    extension (signature: SignatureKesSum)
      def immutableBytes: Bytes =
        signature.verificationKey.decodeBase58
          .concat(signature.signature.decodeBase58)
          .concat(signature.witness.map(_.decodeBase58).immutableBytes)

  given ImmutableBytes[SignatureKesProduct] with
    extension (signature: SignatureKesProduct)
      def immutableBytes: Bytes =
        signature.superSignature.immutableBytes
          .concat(signature.subSignature.immutableBytes)
          .concat(signature.subRoot.decodeBase58.immutableBytes)

  given ImmutableBytes[TransactionOutputReference] with
    extension (reference: TransactionOutputReference)
      def immutableBytes: Bytes =
        reference.transactionId.immutableBytes.concat(
          reference.index.immutableBytes
        )

  given blockchainValueImmutableBytes: ImmutableBytes[Value] with
    extension (value: Value)
      def immutableBytes: Bytes =
        value.quantity.immutableBytes
          .concat(value.accountRegistration.immutableBytes)
          .concat(value.graphEntry.immutableBytes)

  given ImmutableBytes[TransactionInput] with
    extension (input: TransactionInput)
      def immutableBytes: Bytes =
        input.reference.immutableBytes.concat(input.value.immutableBytes)

  given ImmutableBytes[TransactionOutput] with
    extension (output: TransactionOutput)
      def immutableBytes: Bytes =
        output.lockAddress.immutableBytes
          .concat(output.value.immutableBytes)
          .concat(output.account.immutableBytes)

  given ImmutableBytes[AccountRegistration] with
    extension (registration: AccountRegistration)
      def immutableBytes: Bytes = registration.associationLock.immutableBytes
        .concat(registration.stakingRegistration.immutableBytes)

  given ImmutableBytes[GraphEntry] with
    extension (entry: GraphEntry)
      def immutableBytes: Bytes = entry.entry match {
        case GraphEntry.Entry.Vertex(v) =>
          ByteString.copyFromUtf8(v.label).concat(v.data.immutableBytes)
        case GraphEntry.Entry.Edge(e) =>
          ByteString
            .copyFromUtf8(e.label)
            .concat(e.data.immutableBytes)
            .concat(e.a.immutableBytes)
            .concat(e.b.immutableBytes)
        case _ => ZeroBS
      }

  given ImmutableBytes[Lock] with
    extension (lock: Lock)
      def immutableBytes: Bytes =
        lock.value match {
          case l: Lock.Value.Ed25519 => l.value.vk.decodeBase58.immutableBytes
          case _                     => ByteString.empty()
        }

  extension (lock: Lock)
    def address: LockAddress =
      LockAddress(ByteVector(new Blake2b256().hash(lock.immutableBytes.toByteArray)).toBase58)

  given ImmutableBytes[StakingAddress] with
    extension (stakingAddress: StakingAddress) def immutableBytes: Bytes = stakingAddress.value.decodeBase58

  given ImmutableBytes[StakingRegistration] with
    extension (registration: StakingRegistration)
      def immutableBytes: Bytes =
        registration.signature.immutableBytes.concat(
          registration.stakingAddress.immutableBytes
        )

  given ImmutableBytes[LockAddress] with
    extension (lockAddress: LockAddress) def immutableBytes: Bytes = lockAddress.value.decodeBase58

  given ImmutableBytes[Transaction] with
    extension (transaction: Transaction)
      def immutableBytes: Bytes =
        transaction.inputs.immutableBytes
          .concat(transaction.outputs.immutableBytes)
          .concat(transaction.rewardParentBlockId.immutableBytes)
      def signableBytes: Bytes =
        immutableBytes
      def id: TransactionId =
        transaction.transactionId.getOrElse(computedId)
      def computedId: TransactionId =
        TransactionId(
          ByteVector(
            new Blake2b256().hash(immutableBytes.toByteArray)
          ).toBase58
        )
      def withEmbeddedId: Transaction =
        transaction.copy(transactionId = computedId.some)

  given ImmutableBytes[TransactionId] with
    extension (id: TransactionId) def immutableBytes: Bytes = id.value.decodeBase58

  given ImmutableBytes[BlockId] with
    extension (id: BlockId) def immutableBytes: Bytes = id.value.decodeBase58

  given SignableBytes[VrfArgument] with
    extension (argument: VrfArgument)
      def signableBytes: Bytes =
        argument.eta.concat(argument.slot.immutableBytes)

  given ImmutableBytes[struct.Struct] with
    extension (str: struct.Struct)
      def immutableBytes: Bytes =
        str.fields.toList
          .sortBy(_._1)
          .map((key, value) => ByteString.copyFromUtf8(key).concat(value.immutableBytes))
          .immutableBytes

  given Monoid[Bytes] = Monoid.instance(ByteString.EMPTY, _.concat(_))

}

object Codecs:
  val ZeroBS: ByteString = ByteString.copyFrom(Array[Byte](0))
  val OneBS: ByteString = ByteString.copyFrom(Array[Byte](1))

trait ImmutableBytes[T]:
  extension (t: T) def immutableBytes: Bytes

trait SignableBytes[T]:
  extension (t: T) def signableBytes: Bytes

trait ArrayEncodable[T]:
  extension (t: T) def encodeArray: Array[Byte]
trait ArrayDecodable[T]:
  extension (bytes: Array[Byte]) def decodeFromArray: T

trait P2PEncodable[T]:
  extension (t: T) def encodeP2P: Bytes

object P2PEncodable:
  def apply[T: P2PEncodable]: P2PEncodable[T] = summon[P2PEncodable[T]]
trait P2PDecodable[T]:
  extension (bytes: Bytes) def decodeFromP2P: T

object P2PDecodable:
  def apply[T: P2PDecodable]: P2PDecodable[T] = summon[P2PDecodable[T]]

trait P2PCodecs {

  given [T: P2PEncodable]: P2PEncodable[Option[T]] with
    extension (message: Option[T])
      def encodeP2P: Bytes =
        message.fold(ByteString.copyFrom(Array[Byte](0)))(message =>
          ByteString.copyFrom(Array[Byte](1)).concat(message.encodeP2P)
        )

  given [T: P2PDecodable]: P2PDecodable[Option[T]] with
    extension (bytes: Bytes)
      def decodeFromP2P: Option[T] =
        if (bytes.byteAt(0) == 1)
          summon[P2PDecodable[T]].decodeFromP2P(bytes.substring(1)).some
        else none

  given P2PEncodable[BlockHeader] with
    extension (message: BlockHeader) def encodeP2P: Bytes = message.toByteString

  given P2PDecodable[BlockHeader] with
    extension (bytes: Bytes)
      def decodeFromP2P: BlockHeader =
        BlockHeader.parseFrom(bytes.toByteArray)

  given P2PEncodable[BlockBody] with
    extension (message: BlockBody) def encodeP2P: Bytes = message.toByteString

  given P2PDecodable[BlockBody] with
    extension (bytes: Bytes)
      def decodeFromP2P: BlockBody =
        BlockBody.parseFrom(bytes.toByteArray)

  given P2PEncodable[Transaction] with
    extension (message: Transaction) def encodeP2P: Bytes = message.toByteString

  given P2PDecodable[Transaction] with
    extension (bytes: Bytes)
      def decodeFromP2P: Transaction =
        Transaction.parseFrom(bytes.toByteArray)

  given P2PEncodable[BlockId] with
    extension (message: BlockId) def encodeP2P: Bytes = message.value.decodeBase58.immutableBytes

  given P2PDecodable[BlockId] with
    extension (bytes: Bytes) def decodeFromP2P: BlockId = BlockId(ByteVector(bytes.toByteArray).toBase58)

  given P2PEncodable[TransactionId] with
    extension (message: TransactionId) def encodeP2P: Bytes = message.value.decodeBase58.immutableBytes

  given P2PDecodable[TransactionId] with
    extension (bytes: Bytes) def decodeFromP2P: TransactionId = TransactionId(ByteVector(bytes.toByteArray).toBase58)

  given P2PEncodable[PublicP2PState] with
    extension (message: PublicP2PState) def encodeP2P: Bytes = message.toByteString

  given P2PDecodable[PublicP2PState] with
    extension (bytes: Bytes)
      def decodeFromP2P: PublicP2PState =
        PublicP2PState.parseFrom(bytes.toByteArray)

  given P2PEncodable[Bytes] with
    extension (message: Bytes) def encodeP2P: Bytes = message

  given P2PDecodable[Bytes] with
    extension (bytes: Bytes) def decodeFromP2P: Bytes = bytes

  given P2PEncodable[Unit] with
    extension (u: Unit) def encodeP2P: Bytes = ByteString.EMPTY
  given P2PDecodable[Unit] with
    extension (b: Bytes) def decodeFromP2P: Unit = ()

  given P2PEncodable[Long] with
    extension (u: Long) def encodeP2P: Bytes = ByteString.copyFrom(Longs.toByteArray(u))
  given P2PDecodable[Long] with
    extension (b: Bytes) def decodeFromP2P: Long = Longs.fromByteArray(b.toByteArray)

  given [T: P2PDecodable]: Conversion[Bytes, T] =
    P2PDecodable[T].decodeFromP2P

  given [T: P2PEncodable]: Conversion[T, Bytes] =
    P2PEncodable[T].encodeP2P
}

trait ArrayCodecs {

  given ArrayEncodable[BlockId] with
    extension (id: BlockId)
      def encodeArray: Array[Byte] =
        id.value.decodeBase58.toByteArray

  given ArrayDecodable[BlockId] with
    extension (array: Array[Byte])
      def decodeFromArray: BlockId = BlockId(
        ByteVector(array.ensuring(_.length == 32)).toBase58
      )

  given ArrayEncodable[TransactionId] with
    extension (id: TransactionId)
      def encodeArray: Array[Byte] =
        id.value.decodeBase58.toByteArray

  given ArrayDecodable[TransactionId] with
    extension (array: Array[Byte])
      def decodeFromArray: TransactionId = TransactionId(
        ByteVector(array.ensuring(_.length == 32)).toBase58
      )

  given ArrayEncodable[Byte] with
    extension (b: Byte) def encodeArray: Array[Byte] = Array(b)

  given ArrayEncodable[(Long, BlockId)] with
    extension (t: (Long, BlockId))
      def encodeArray: Array[Byte] =
        t._1.immutableBytes.toByteArray ++ t._2.encodeArray

  given ArrayDecodable[(Long, BlockId)] with
    extension (array: Array[Byte])
      def decodeFromArray: (Long, BlockId) =
        (
          Longs.fromByteArray(array.slice(0, 8)),
          BlockId(ByteVector(array.slice(8, array.length)).toBase58)
        )

  given ArrayEncodable[BlockHeader] with
    extension (v: BlockHeader) def encodeArray: Array[Byte] = v.toByteArray

  given ArrayDecodable[BlockHeader] with
    extension (array: Array[Byte]) def decodeFromArray: BlockHeader = BlockHeader.parseFrom(array)

  given ArrayEncodable[BlockBody] with
    extension (v: BlockBody) def encodeArray: Array[Byte] = v.toByteArray

  given ArrayDecodable[BlockBody] with
    extension (array: Array[Byte]) def decodeFromArray: BlockBody = BlockBody.parseFrom(array)

  given ArrayEncodable[Transaction] with
    extension (v: Transaction) def encodeArray: Array[Byte] = v.toByteArray

  given ArrayDecodable[Transaction] with
    extension (array: Array[Byte]) def decodeFromArray: Transaction = Transaction.parseFrom(array)

  given ArrayEncodable[BitVector] with
    extension (v: BitVector) def encodeArray: Array[Byte] = v.toByteArray

  given ArrayDecodable[BitVector] with
    extension (array: Array[Byte]) def decodeFromArray: BitVector = BitVector(array)

  given ArrayEncodable[TransactionOutputReference] with
    extension (v: TransactionOutputReference)
      def encodeArray: Array[Byte] =
        v.transactionId.encodeArray ++ Ints.toByteArray(v.index)

  given ArrayDecodable[TransactionOutputReference] with
    extension (array: Array[Byte])
      def decodeFromArray: TransactionOutputReference =
        TransactionOutputReference(
          summon[ArrayDecodable[TransactionId]].decodeFromArray(array.slice(0, 32)),
          Ints.fromByteArray(array.slice(32, 36))
        )

  given ArrayEncodable[LockAddress] with
    extension (v: LockAddress)
      def encodeArray: Array[Byte] =
        v.value.encodeArray

  given ArrayDecodable[LockAddress] with
    extension (array: Array[Byte])
      def decodeFromArray: LockAddress =
        LockAddress(summon[ArrayDecodable[String]].decodeFromArray(array))

  given ArrayEncodable[List[TransactionOutputReference]] with
    extension (v: List[TransactionOutputReference])
      def encodeArray: Array[Byte] =
        Ints.toByteArray(v.length) ++ v.toArray.flatMap(v => v.encodeArray)

  given ArrayDecodable[List[TransactionOutputReference]] with
    extension (array: Array[Byte])
      def decodeFromArray: List[TransactionOutputReference] =
        List.tabulate(Ints.fromByteArray(array.slice(0, 4)))(index =>
          array.slice(4 + index * 36, 4 + (index + 1) * 36).decodeFromArray
        )

  given ArrayEncodable[Long] with
    extension (v: Long)
      def encodeArray: Array[Byte] =
        Longs.toByteArray(v)

  given ArrayDecodable[Long] with
    extension (array: Array[Byte])
      def decodeFromArray: Long =
        Longs.fromByteArray(array)

  given ArrayEncodable[Unit] with
    extension (v: Unit)
      def encodeArray: Array[Byte] =
        Array[Byte](0)

  given ArrayEncodable[ActiveStaker] with
    extension (v: ActiveStaker)
      def encodeArray: Array[Byte] =
        v.toByteArray

  given ArrayDecodable[ActiveStaker] with
    extension (array: Array[Byte])
      def decodeFromArray: ActiveStaker =
        ActiveStaker.parseFrom(array)

  given ArrayEncodable[Array[Byte]] with
    extension (v: Array[Byte])
      def encodeArray: Array[Byte] =
        v

  given ArrayDecodable[Array[Byte]] with
    extension (array: Array[Byte])
      def decodeFromArray: Array[Byte] =
        array

  given ArrayEncodable[String] with
    extension (v: String)
      def encodeArray: Array[Byte] =
        v.getBytes(StandardCharsets.UTF_8)

  given ArrayDecodable[String] with
    extension (array: Array[Byte])
      def decodeFromArray: String =
        new String(array, StandardCharsets.UTF_8)

}
