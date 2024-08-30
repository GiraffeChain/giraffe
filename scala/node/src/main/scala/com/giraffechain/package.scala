package com

import cats.data.{EitherT, NonEmptyChain}
import com.google.protobuf.ByteString
import com.giraffechain.models.*

package object giraffechain {
  type ValidationResult[F[_]] = EitherT[F, NonEmptyChain[String], Unit]
  type Bytes = ByteString
  type Slot = Long
  type Epoch = Long
  type Height = Long
  type Timestamp = Long

  type FetchHeader[F[_]] = BlockId => F[BlockHeader]
  type FetchBody[F[_]] = BlockId => F[BlockBody]
  type FetchTransaction[F[_]] = TransactionId => F[Transaction]
  type FetchTransactionOutput[F[_]] =
    TransactionOutputReference => F[TransactionOutput]

  given Conversion[Bytes, Array[Byte]] = _.toByteArray
  given Conversion[Array[Byte], Bytes] = ByteString.copyFrom
}
