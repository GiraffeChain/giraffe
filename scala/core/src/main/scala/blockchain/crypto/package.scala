package blockchain

import com.google.protobuf.ByteString
import blockchain.models as protoModels

package object crypto:

  given protoToCryptoVerificationKeyKesProduct: Conversion[
    protoModels.VerificationKeyKesProduct,
    VerificationKeyKesProduct
  ] =
    kesProduct =>
      VerificationKeyKesProduct(kesProduct.value.toByteArray, kesProduct.step)

  given cryptoToProtoVerificationKeyKesProduct: Conversion[
    VerificationKeyKesProduct,
    protoModels.VerificationKeyKesProduct
  ] =
    kesProduct =>
      protoModels.VerificationKeyKesProduct(
        ByteString.copyFrom(kesProduct.value),
        kesProduct.step
      )

  given consensusToCryptoSignatureKesSum
      : Conversion[protoModels.SignatureKesSum, SignatureKesSum] =
    kesSum =>
      SignatureKesSum(
        kesSum.verificationKey.toByteArray,
        kesSum.signature.toByteArray,
        kesSum.witness.map(_.toByteArray)
      )

  given cryptoToConsensusVerificationKeyKesSum
      : Conversion[SignatureKesSum, protoModels.SignatureKesSum] =
    kesSum =>
      protoModels.SignatureKesSum(
        ByteString.copyFrom(kesSum.verificationKey),
        ByteString.copyFrom(kesSum.signature),
        kesSum.witness.map(ByteString.copyFrom)
      )

  given consensusToCryptoSignatureKesProduct
      : Conversion[protoModels.SignatureKesProduct, SignatureKesProduct] =
    kesProduct =>
      SignatureKesProduct(
        kesProduct.superSignature,
        kesProduct.subSignature,
        kesProduct.subRoot.toByteArray
      )

  given cryptoToConsensusVerificationKeyKesProduct
      : Conversion[SignatureKesProduct, protoModels.SignatureKesProduct] =
    kesProduct =>
      protoModels.SignatureKesProduct(
        kesProduct.superSignature,
        kesProduct.subSignature,
        ByteString.copyFrom(kesProduct.subRoot)
      )
