package blockchain.p2p

import blockchain.models.PublicP2PState
import cats.Monad
import cats.effect.{Async, Ref, Resource}
import cats.implicits.*
import cats.effect.implicits.*
import com.comcast.ip4s.SocketAddress
import fs2.io.net.Socket

case class PeerState[F[_]](
    socket: Socket[F],
    publicStateRef: Ref[F, PublicP2PState],
    finalizers: Ref[F, List[F[Unit]]],
    outboundAddress: Option[SocketAddress[_]]
):
  def close()(using Monad[F]): F[Unit] =
    finalizers.getAndSet(Nil).flatMap(_.sequence).void

object PeerState:
  def make[F[_]: Async](
      socket: Socket[F],
      publicP2PState: PublicP2PState,
      outboundAddress: Option[SocketAddress[_]]
  ): Resource[F, PeerState[F]] =
    (Ref.of(publicP2PState), Ref.of(List.empty[F[Unit]]))
      .mapN(PeerState(socket, _, _, outboundAddress))
      .toResource
      .flatTap(state => Resource.onFinalize(state.close()))
