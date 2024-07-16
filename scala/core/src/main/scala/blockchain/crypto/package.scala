package blockchain

import blockchain.models as protoModels
import blockchain.codecs.*
import scodec.bits.ByteVector

package object crypto:

  given protoToCryptoVerificationKeyKesProduct: Conversion[
    protoModels.VerificationKeyKesProduct,
    VerificationKeyKesProduct
  ] =
    kesProduct => VerificationKeyKesProduct(kesProduct.value.decodeBase58.toByteArray, kesProduct.step)

  given cryptoToProtoVerificationKeyKesProduct: Conversion[
    VerificationKeyKesProduct,
    protoModels.VerificationKeyKesProduct
  ] =
    kesProduct =>
      protoModels.VerificationKeyKesProduct(
        ByteVector(kesProduct.value).toBase58,
        kesProduct.step
      )

  given consensusToCryptoSignatureKesSum: Conversion[protoModels.SignatureKesSum, SignatureKesSum] =
    kesSum =>
      SignatureKesSum(
        kesSum.verificationKey.decodeBase58.toByteArray,
        kesSum.signature.decodeBase58.toByteArray,
        kesSum.witness.map(_.decodeBase58.toByteArray)
      )

  given cryptoToConsensusVerificationKeyKesSum: Conversion[SignatureKesSum, protoModels.SignatureKesSum] =
    kesSum =>
      protoModels.SignatureKesSum(
        ByteVector(kesSum.verificationKey).toBase58,
        ByteVector(kesSum.signature).toBase58,
        kesSum.witness.map(ByteVector(_).toBase58)
      )

  given consensusToCryptoSignatureKesProduct: Conversion[protoModels.SignatureKesProduct, SignatureKesProduct] =
    kesProduct =>
      SignatureKesProduct(
        kesProduct.superSignature,
        kesProduct.subSignature,
        kesProduct.subRoot.decodeBase58.toByteArray
      )

  given cryptoToConsensusVerificationKeyKesProduct: Conversion[SignatureKesProduct, protoModels.SignatureKesProduct] =
    kesProduct =>
      protoModels.SignatureKesProduct(
        kesProduct.superSignature,
        kesProduct.subSignature,
        ByteVector(kesProduct.subRoot).toBase58
      )
