package blockchain.codecs

import blockchain.Bytes
import blockchain.consensus.UnsignedBlockHeader.PartialOperationalCertificate
import blockchain.consensus.{UnsignedBlockHeader, VrfArgument}
import blockchain.crypto.Blake2b256
import blockchain.models.*
import cats.Monoid
import cats.implicits.*
import com.google.common.primitives.{Doubles, Ints, Longs}
import com.google.protobuf.{ByteString, struct}

trait Codecs {

  given structValueImmutableBytes: ImmutableBytes[struct.Value] with
    extension (value: struct.Value)
      def immutableBytes: Bytes =
        value.kind match {
          case struct.Value.Kind.Empty        => ZeroBS
          case struct.Value.Kind.NullValue(_) => ZeroBS
          case struct.Value.Kind.NumberValue(num) =>
            num.immutableBytes
          case struct.Value.Kind.StringValue(string) =>
            string.immutableBytes
          case struct.Value.Kind.BoolValue(bool) =>
            bool.immutableBytes
          case struct.Value.Kind.StructValue(str) =>
            str.immutableBytes
          case struct.Value.Kind.ListValue(lv) =>
            lv.values.immutableBytes
        }

  given ImmutableBytes[Long] with
    extension (long: Long)
      def immutableBytes: Bytes = ByteString.copyFrom(Longs.toByteArray(long))

  given ImmutableBytes[Int] with
    extension (int: Int)
      def immutableBytes: Bytes = ByteString.copyFrom(Ints.toByteArray(int))

  given ImmutableBytes[Double] with
    extension (double: Double)
      def immutableBytes: Bytes =
        double.toString.immutableBytes // TODO precision

  given ImmutableBytes[Boolean] with
    extension (bool: Boolean)
      def immutableBytes: Bytes = if (bool) OneBS else ZeroBS

  given ImmutableBytes[String] with
    extension (s: String) def immutableBytes: Bytes = ByteString.copyFromUtf8(s)

  given ImmutableBytes[ByteString] with
    extension (b: ByteString) def immutableBytes: Bytes = b

  given ImmutableBytes[BlockHeader] with
    extension (header: BlockHeader)
      def id: BlockId =
        header.headerId.getOrElse(computedId)
      def computedId: BlockId =
        BlockId(
          ByteString.copyFrom(
            new Blake2b256().hash(immutableBytes.toByteArray())
          )
        )
      def withEmbeddedId: BlockHeader =
        header.copy(headerId = computedId.some)
      def immutableBytes: Bytes =
        header.parentHeaderId.immutableBytes
          .concat(header.parentSlot.immutableBytes)
          .concat(header.txRoot)
          .concat(header.timestamp.immutableBytes)
          .concat(header.height.immutableBytes)
          .concat(header.slot.immutableBytes)
          .concat(header.eligibilityCertificate.immutableBytes)
          .concat(header.operationalCertificate.immutableBytes)
          .concat(header.metadata)
          .concat(header.account.immutableBytes)

  given SignableBytes[UnsignedBlockHeader] with
    extension (header: UnsignedBlockHeader)
      def signableBytes: Bytes =
        header.parentHeaderId.immutableBytes
          .concat(header.parentSlot.immutableBytes)
          .concat(header.txRoot)
          .concat(header.timestamp.immutableBytes)
          .concat(header.height.immutableBytes)
          .concat(header.slot.immutableBytes)
          .concat(header.eligibilityCertificate.immutableBytes)
          .concat(header.partialOperationalCertificate.immutableBytes)
          .concat(header.metadata)
          .concat(header.account.immutableBytes)

  given ImmutableBytes[EligibilityCertificate] with
    extension (certificate: EligibilityCertificate)
      def immutableBytes: Bytes =
        certificate.vrfSig
          .concat(certificate.vrfVK)
          .concat(certificate.thresholdEvidence)
          .concat(certificate.eta)

  given ImmutableBytes[OperationalCertificate] with
    extension (certificate: OperationalCertificate)
      def immutableBytes: Bytes =
        certificate.parentVK.immutableBytes
          .concat(certificate.parentSignature.immutableBytes)
          .concat(certificate.childVK)
          .concat(certificate.childSignature)

  given ImmutableBytes[PartialOperationalCertificate] with
    extension (certificate: PartialOperationalCertificate)
      def immutableBytes: Bytes =
        certificate.parentVK.immutableBytes
          .concat(certificate.parentSignature.immutableBytes)
          .concat(certificate.childVK)

  given ImmutableBytes[VerificationKeyKesProduct] with
    extension (vk: VerificationKeyKesProduct)
      def immutableBytes: Bytes = vk.value.concat(vk.step.immutableBytes)

  given [T: ImmutableBytes]: ImmutableBytes[Seq[T]] with
    extension (iterable: Seq[T])
      def immutableBytes: Bytes =
        iterable.foldLeft(iterable.size.immutableBytes)((res, t) =>
          res.concat(t.immutableBytes)
        )

  private val ZeroBS = ByteString.copyFrom(Array[Byte](0))
  private val OneBS = ByteString.copyFrom(Array[Byte](1))

  given [T: ImmutableBytes]: ImmutableBytes[Option[T]] with
    extension (o: Option[T])
      def immutableBytes: Bytes =
        o.fold(ZeroBS)(v => OneBS.concat(v.immutableBytes))

  given ImmutableBytes[SignatureKesSum] with
    extension (signature: SignatureKesSum)
      def immutableBytes: Bytes =
        signature.verificationKey
          .concat(signature.signature)
          .concat(signature.witness.immutableBytes)

  given ImmutableBytes[SignatureKesProduct] with
    extension (signature: SignatureKesProduct)
      def immutableBytes: Bytes =
        signature.superSignature.immutableBytes
          .concat(signature.subSignature.immutableBytes)
          .concat(signature.subRoot)

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
          v.label.immutableBytes.concat(v.data.immutableBytes)
        case GraphEntry.Entry.Edge(e) =>
          e.label.immutableBytes
            .concat(e.data.immutableBytes)
            .concat(e.a.immutableBytes)
            .concat(e.b.immutableBytes)
        case _ => ZeroBS
      }

  given ImmutableBytes[Lock] with
    extension (lock: Lock)
      def immutableBytes: Bytes =
        lock.value match {
          case l: Lock.Value.Ed25519 => l.value.vk
          case _                     => ByteString.empty()
        }

  given ImmutableBytes[StakingAddress] with
    extension (stakingAddress: StakingAddress)
      def immutableBytes: Bytes = stakingAddress.value

  given ImmutableBytes[StakingRegistration] with
    extension (registration: StakingRegistration)
      def immutableBytes: Bytes =
        registration.signature.immutableBytes.concat(
          registration.stakingAddress.immutableBytes
        )

  given ImmutableBytes[LockAddress] with
    extension (lockAddress: LockAddress)
      def immutableBytes: Bytes = lockAddress.value

  given ImmutableBytes[Transaction] with
    extension (transaction: Transaction)
      def immutableBytes: Bytes =
        transaction.inputs.immutableBytes
          .concat(transaction.outputs.immutableBytes)
          .concat(transaction.rewardParentBlockId.immutableBytes)
      def id: TransactionId =
        transaction.transactionId.getOrElse(computedId)
      def computedId: TransactionId =
        TransactionId(
          ByteString.copyFrom(
            new Blake2b256().hash(immutableBytes.toByteArray())
          )
        )
      def withEmbeddedId: Transaction =
        transaction.copy(transactionId = computedId.some)

  given ImmutableBytes[TransactionId] with
    extension (id: TransactionId) def immutableBytes: Bytes = id.value

  given ImmutableBytes[BlockId] with
    extension (id: BlockId) def immutableBytes: Bytes = id.value

  given SignableBytes[VrfArgument] with
    extension (argument: VrfArgument)
      def signableBytes: Bytes =
        argument.eta.concat(argument.slot.immutableBytes)

  given ImmutableBytes[struct.Struct] with
    extension (str: struct.Struct)
      def immutableBytes: Bytes =
        str.fields.toList
          .sortBy(_._1)
          .map((key, value) => key.immutableBytes.concat(value.immutableBytes))
          .immutableBytes

  given Monoid[Bytes] = Monoid.instance(ByteString.EMPTY, _.concat(_))

}

trait ImmutableBytes[T]:
  extension (t: T) def immutableBytes: Bytes

trait SignableBytes[T]:
  extension (t: T) def signableBytes: Bytes
