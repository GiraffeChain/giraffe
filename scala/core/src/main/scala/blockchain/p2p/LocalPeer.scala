package blockchain.p2p

import blockchain.*
import blockchain.models.*
import blockchain.utility.*
import cats.effect.{Async, Resource}
import cats.data.OptionT
import cats.implicits.*
import cats.effect.implicits.*
import cats.effect.std.Random
import com.google.protobuf.ByteString

case class LocalPeer(connectedPeer: ConnectedPeer, sk: Array[Byte], vk: Array[Byte])

object LocalPeer:
  def make[F[_]: Async: Random](
      core: BlockchainCore[F],
      publicHost: Option[String],
      publicPort: Option[Int]
  ): Resource[F, LocalPeer] =
    loadP2PKeys(core)
      .map((sk, vk) => LocalPeer(ConnectedPeer(PeerId(ByteString.copyFrom(vk)), publicHost, publicPort), sk, vk))
      .toResource

  def loadP2PKeys[F[_]: Async: Random](core: BlockchainCore[F]): F[(Array[Byte], Array[Byte])] =
    OptionT(core.dataStores.metadata.get("p2p-sk"))
      .getOrElseF(
        core.cryptoResources.ed25519
          .use(_.generateSecretKey[F])
          .flatTap(core.dataStores.metadata.put("p2p-sk", _))
      )
      .flatMap(sk => core.cryptoResources.ed25519.useSync(_.getVerificationKey(sk)).tupleLeft(sk))
