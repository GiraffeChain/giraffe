package blockchain.p2p

import blockchain.crypto.CryptoResources
import cats.implicits.*
import blockchain.models.PeerId
import cats.MonadThrow
import cats.data.OptionT
import cats.effect.Sync
import cats.effect.std.Random
import com.google.protobuf.ByteString
import fs2.Chunk
import fs2.io.net.Socket

object Handshake:
  def run[F[_]: Sync: Random: CryptoResources](
      socket: Socket[F],
      magicBytes: Array[Byte],
      sk: Array[Byte],
      vk: Array[Byte]
  ): F[PeerId] =
    for {
      magicBytesChunk <- Chunk.array(magicBytes).pure[F]
      _ <- socket.write(magicBytesChunk)
      _ <- OptionT(socket.read(magicBytes.length))
        .getOrRaise(new IllegalArgumentException("No MagicBytes Provided"))
        .ensure(new IllegalArgumentException("MagicBytes Mismatch"))(
          _ == magicBytesChunk
        )
      _ <- socket.write(Chunk.array(vk))
      remoteVk <- OptionT(socket.read(vk.length))
        .map(_.toArray)
        .getOrRaise(new IllegalArgumentException("No VK Provided"))
      localChallenge <- Random[F].nextBytes(32)
      _ <- socket.write(Chunk.array(localChallenge))
      remoteChallenge <- OptionT(socket.read(localChallenge.length))
        .map(_.toArray)
        .getOrRaise(new IllegalArgumentException("No Challenge Provided"))
      localSignature <- CryptoResources[F].ed25519.use(ed =>
        Sync[F].delay(ed.sign(sk, remoteChallenge))
      )
      _ <- socket.write(Chunk.array(localSignature))
      remoteSignature <- OptionT(socket.read(localSignature.length))
        .getOrRaise(new IllegalArgumentException("No Signature Provided"))
      _ <- CryptoResources[F].ed25519
        .use(ed =>
          Sync[F]
            .delay(ed.verify(remoteSignature.toArray, localChallenge, remoteVk))
        )
        .ensure(new IllegalArgumentException("Invalid Signature"))(identity)
    } yield PeerId(ByteString.copyFrom(remoteVk))
