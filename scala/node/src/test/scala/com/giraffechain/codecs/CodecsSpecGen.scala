package com.giraffechain.codecs

import com.giraffechain.codecs.given
import com.giraffechain.models.*
import com.google.protobuf.ByteString

import scala.util.Random

object CodecsSpecGen extends App {

  val tx = Transaction(
    inputs = List(
      TransactionInput(randomTxoRef()),
      TransactionInput(randomTxoRef()),
      TransactionInput(randomTxoRef()),
      TransactionInput(randomTxoRef())
    ),
    outputs = List(
      TransactionOutput(
        randomLockAddress(),
        Random.nextInt(Int.MaxValue),
        Some(randomTxoRef())
      )
    )
  )

  val spec = Spec(
    txHex = scodec.bits.ByteVector(tx.toByteArray).toHex,
    signableBytesHex = scodec.bits.ByteVector(tx.signableBytes.toByteArray).toHex
  )
  println(spec.txHex)
  println(spec.signableBytesHex)

  def randomByteString(length: Int): ByteString =
    ByteString.copyFrom(Random.nextBytes(length))

  def base58(byteString: ByteString): String =
    scodec.bits.ByteVector(byteString.toByteArray).toBase58

  def randomTxoRef(): TransactionOutputReference =
    TransactionOutputReference(Some(TransactionId(base58(randomByteString(32)))), Random.nextInt())

  def randomLockAddress(): LockAddress =
    LockAddress(base58(randomByteString(32)))
}
