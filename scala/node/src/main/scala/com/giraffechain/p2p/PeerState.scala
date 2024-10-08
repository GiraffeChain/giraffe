package com.giraffechain.p2p

import cats.Monad
import cats.effect.implicits.*
import cats.effect.{Async, Ref, Resource}
import cats.implicits.*
import com.giraffechain.BlockchainCore
import com.giraffechain.models.{PeerId, PublicP2PState}
import fs2.io.net.Socket
import org.typelevel.log4cats.Logger

// TODO: DisconnectedPeerState
case class PeerState[F[_]](
    peerId: PeerId,
    socket: Socket[F],
    publicStateRef: Ref[F, PublicP2PState],
    finalizers: Ref[F, List[F[Unit]]],
    outboundAddress: Option[PeerAddress],
    interface: PeerBlockchainInterface[F],
    abort: F[Unit]
):
  def close()(using Monad[F]): F[Unit] =
    finalizers.getAndSet(Nil).flatMap(_.sequence).void

object PeerState:
  def make[F[_]: Async: Logger](
      socket: Socket[F],
      core: BlockchainCore[F],
      manager: PeersManager[F],
      publicP2PState: PublicP2PState,
      outboundAddress: Option[PeerAddress],
      abort: F[Unit]
  ): Resource[F, PeerState[F]] =
    for {
      publicStateRef <- Ref.of(publicP2PState).toResource
      finalizersRef <- Ref.of(List.empty[F[Unit]]).toResource
      portQueues <- AllPortQueues.make[F]
      readerWriter <- MultiplexedReaderWriter.forSocket(socket)
      peerCache <- PeerCache.make[F]
      interface = new PeerBlockchainInterfaceImpl[F](core, manager, portQueues, readerWriter, peerCache)
      state = PeerState(
        publicP2PState.localPeer.peerId,
        socket,
        publicStateRef,
        finalizersRef,
        outboundAddress,
        interface,
        abort
      )
      _ <- Resource.onFinalize(state.close())
    } yield state
