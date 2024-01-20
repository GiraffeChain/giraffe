package blockchain.p2p

import blockchain.models.PublicP2PState
import cats.Monad
import cats.effect.{Ref, Async, Resource}
import cats.implicits.*
import fs2.io.net.Socket

case class PeerState[F[_]](
    socket: Socket[F],
    publicStateRef: Ref[F, PublicP2PState],
    finalizers: Ref[F, List[F[Unit]]]
):
  def close()(using Monad[F]): F[Unit] =
    finalizers.getAndSet(Nil).flatMap(_.sequence).void

object PeerState:
  def make[F[_]: Async](
      socket: Socket[F],
      publicP2PState: PublicP2PState
  ): Resource[F, PeerState[F]] =
    Resource.make(
      (Ref.of(publicP2PState), Ref.of(List.empty[F[Unit]]))
        .mapN(PeerState(socket, _, _))
    )(state => state.finalizers.getAndSet(Nil).flatMap(_.sequence).void)
