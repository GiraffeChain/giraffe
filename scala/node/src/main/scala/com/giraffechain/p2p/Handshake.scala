package com.giraffechain.p2p

import com.giraffechain.crypto.CryptoResources
import cats.implicits.*
import com.giraffechain.models.PeerId
import com.giraffechain.utility.*
import cats.MonadThrow
import cats.data.OptionT
import cats.effect.Sync
import cats.effect.std.Random
import fs2.Chunk
import fs2.io.net.Socket
import scodec.bits.ByteVector

object Handshake:
  def run[F[_]: Sync: Random: CryptoResources](
      socket: Socket[F],
      magicBytes: Array[Byte],
      sk: Array[Byte],
      vk: Array[Byte]
  ): F[PeerId] =
    run(
      length =>
        OptionT(socket.read(length)).getOrRaise(new IllegalArgumentException(s"Expected $length bytes")).map(_.toArray),
      data => socket.write(Chunk.array(data)),
      magicBytes,
      sk,
      vk
    )

  def run[F[_]: Sync: Random: CryptoResources](
      read: Int => F[Array[Byte]],
      write: Array[Byte] => F[Unit],
      magicBytes: Array[Byte],
      sk: Array[Byte],
      vk: Array[Byte]
  ): F[PeerId] =
    for {
      ed25519 <- CryptoResources[F].ed25519.pure[F]
      exchanger = exchange(read, write)
      _ <- exchanger(magicBytes).ensure(new IllegalArgumentException("MagicBytes Mismatch"))(
        java.util.Arrays.equals(_, magicBytes)
      )
      remoteVk <- exchanger(vk)
      localChallenge <- Random[F].nextBytes(32)
      remoteChallenge <- exchanger(localChallenge)
      localSignature <- ed25519.useSync(_.sign(sk, remoteChallenge))
      remoteSignature <- exchanger(localSignature)
      signatureIsValid <- ed25519.useSync(_.verify(remoteSignature, localChallenge, remoteVk))
      _ <- Sync[F].raiseWhen(!signatureIsValid)(new IllegalArgumentException("Invalid Signature"))
    } yield PeerId(ByteVector(remoteVk).toBase58)

  private def exchange[F[_]: MonadThrow](read: Int => F[Array[Byte]], write: Array[Byte] => F[Unit])(
      data: Array[Byte]
  ): F[Array[Byte]] =
    write(data) >> read(data.length)
