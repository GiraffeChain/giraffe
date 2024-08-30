package com.giraffechain.p2p

import com.giraffechain.*
import com.giraffechain.crypto.CryptoResources
import com.giraffechain.models.*
import com.giraffechain.utility.*
import cats.effect.{Async, Resource}
import cats.data.OptionT
import cats.implicits.*
import cats.effect.implicits.*
import cats.effect.std.Random
import scodec.bits.ByteVector

case class LocalPeer(connectedPeer: ConnectedPeer, sk: Array[Byte], vk: Array[Byte])

object LocalPeer:
  def make[F[_]: Async: Random: CryptoResources](
      core: BlockchainCore[F],
      publicHost: Option[String],
      publicPort: Option[Int]
  ): Resource[F, LocalPeer] =
    loadP2PKeys(core)
      .map((sk, vk) => LocalPeer(ConnectedPeer(PeerId(ByteVector(vk).toBase58), publicHost, publicPort), sk, vk))
      .toResource

  def loadP2PKeys[F[_]: Async: Random: CryptoResources](core: BlockchainCore[F]): F[(Array[Byte], Array[Byte])] =
    OptionT(core.dataStores.metadata.get("p2p-sk"))
      .getOrElseF(
        CryptoResources[F].ed25519
          .use(_.generateSecretKey[F])
          .flatTap(core.dataStores.metadata.put("p2p-sk", _))
      )
      .flatMap(sk => CryptoResources[F].ed25519.useSync(_.getVerificationKey(sk)).tupleLeft(sk))
