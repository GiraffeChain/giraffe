package blockchain.p2p

import blockchain.codecs.{*, given}
import blockchain.consensus.ChainSelectionOutcome
import blockchain.{BlockchainCore, Bytes, Genesis, Height}
import blockchain.crypto.CryptoResources
import blockchain.ledger.{MempoolChange, TransactionValidationContext}
import blockchain.models.*
import blockchain.utility.Ratio
import cats.{Monad, MonadThrow}
import cats.data.OptionT
import cats.effect.std.{Queue, Random}
import cats.effect.{Async, Ref, Resource}
import cats.implicits.*
import cats.effect.implicits.*
import cats.effect.kernel.{Deferred, Outcome}
import com.comcast.ip4s.{Host, Port, SocketAddress}
import com.google.protobuf.ByteString
import fs2.io.net.Socket
import org.typelevel.log4cats.Logger
import fs2.{Chunk, Stream}
import org.typelevel.log4cats.slf4j.{Slf4jFactory, given}

import scala.concurrent.duration.*

class PeersManager[F[_]: Async: Random](
    core: BlockchainCore[F],
    localPeer: ConnectedPeer,
    sk: Array[Byte],
    vk: Array[Byte],
    magicBytes: Array[Byte],
    connectOutbound: SocketAddress[_] => F[Unit],
    stateRef: Ref[F, PeersManager.State[F]]
):

  def close(): F[Unit] =
    stateRef
      .getAndSet(PeersManager.State(Map.empty, Map.empty))
      .flatMap(state => state.connectedPeers.values.toList.traverse(_.close()))
      .void

  def connectNext(): F[Unit] =
    for {
      state <- stateRef.get
      targets <- state.connectedPeers.values.toList
        .traverse(
          _.publicStateRef.get.map(
            _.peers.flatMap(p =>
              (p.host.flatMap(Host.fromString), p.port.flatMap(Port.fromInt))
                .mapN(SocketAddress.apply)
                .tupleLeft(p.peerId)
            )
          )
        )
        .map(
          _.flatten.toMap
            .removed(localPeer.peerId)
            .removedAll(state.connectedPeers.keys)
            .values
            .toList
        )
      _ <- Async[F].whenA(targets.nonEmpty)(
        Random[F].elementOf(targets).flatMap(connectOutbound)
      )
    } yield ()

  def handleSocket(socket: Socket[F]): F[Unit] = {
    val resource = for {
      _ <- Resource.onFinalize(socket.endOfInput *> socket.endOfOutput)
      given CryptoResources[F] = core.cryptoResources
      remotePeerId <- Handshake.run(socket, magicBytes, sk, vk).toResource
      given Logger[F] <- Slf4jFactory
        .fromName(show"Blockchain.Peer($remotePeerId)")
        .toResource
      peerState <- PeerState.make(
        socket,
        PublicP2PState(localPeer = ConnectedPeer(remotePeerId))
      )
      _ <- Resource.make(
        stateRef.update(_.withConnectedPeer(remotePeerId, peerState))
      )(_ => stateRef.update(_.withDisconnectedPeer(remotePeerId, peerState)))
      portQueues <- AllPortQueues.make[F]
      readerWriter = MultiplexedReaderWriter.forSocket(socket)
      interface = new PeerBlockchainInterface[F](
        core,
        peerState,
        this,
        portQueues,
        readerWriter
      )
      handler = new PeerBlockchainHandler[F](
        core,
        interface,
        onPeerStateGossiped(remotePeerId, _)
      )
      _ <- interface.background.merge(handler.handle).compile.drain.toResource
    } yield ()

    resource.use_
  }

  def currentState: F[PublicP2PState] =
    stateRef.get
      .flatMap(
        _.connectedPeers.values.toList
          .traverse(_.publicStateRef.get.map(_.localPeer))
      )
      .map(PublicP2PState(localPeer, _))

  def onPeerStateGossiped(peerId: PeerId, publicState: PublicP2PState) =
    stateRef.get.flatMap(
      _.connectedPeers(peerId).publicStateRef.set(publicState)
    )

object PeersManager:

  def make[F[_]: Async: Random](
      core: BlockchainCore[F],
      localPeer: ConnectedPeer,
      magicBytes: Array[Byte],
      connectOutbound: SocketAddress[_] => F[Unit]
  ): Resource[F, PeersManager[F]] =
    (
      Ref.of(State[F](Map.empty, Map.empty)),
      loadP2PKeys(core)
    )
      .mapN((stateRef, p2pKeys) =>
        new PeersManager(
          core,
          localPeer,
          p2pKeys._1,
          p2pKeys._2,
          magicBytes,
          connectOutbound,
          stateRef
        )
      )
      .toResource
      .flatTap(manager => Resource.onFinalize(Async[F].defer(manager.close())))
      .flatTap(manager =>
        Stream
          .awakeDelay(30.seconds)
          .evalTap(_ => manager.connectNext())
          .compile
          .drain
          .background
      )

  private def loadP2PKeys[F[_]: Async: Random](core: BlockchainCore[F]) =
    OptionT(core.dataStores.metadata.get("p2p-sk"))
      .getOrElseF(
        Random[F]
          .nextBytes(32)
          .flatTap(core.dataStores.metadata.put("p2p-sk", _))
      )
      .flatMap(sk =>
        core.cryptoResources.ed25519
          .use(e => Async[F].delay(e.getVerificationKey(sk)))
          .tupleLeft(sk)
      )

  case class State[F[_]](
      connectedPeers: Map[PeerId, PeerState[F]],
      disconnectedPeers: Map[PeerId, PeerState[F]]
  ):
    def withConnectedPeer(peerId: PeerId, peerState: PeerState[F]) =
      copy(
        connectedPeers = connectedPeers.updated(peerId, peerState),
        disconnectedPeers = disconnectedPeers.removed(peerId)
      )
    def withDisconnectedPeer(peerId: PeerId, peerState: PeerState[F]) =
      copy(
        connectedPeers = connectedPeers.removed(peerId),
        disconnectedPeers = disconnectedPeers.updated(peerId, peerState)
      )

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

case class MultiplexedReaderWriter[F[_]](
    read: Stream[F, (Int, Bytes)],
    write: (Int, Bytes) => F[Unit]
)

object MultiplexedReaderWriter:
  def forSocket[F[_]: Monad](socket: Socket[F]) = {
    val writer = MultiplexedFraming.writer(socket)
    MultiplexedReaderWriter[F](
      MultiplexedFraming(socket).map((port, chunk) => (port, ByteString.copyFrom(chunk.toByteBuffer))),
      (port, data) => writer.apply(port, Chunk.byteBuffer(data.asReadOnlyByteBuffer()))
    )
  }

class PeerBlockchainInterface[F[_]: Async: Logger](
    core: BlockchainCore[F],
    remotePeerState: PeerState[F],
    manager: PeersManager[F],
    allPortQueues: AllPortQueues[F],
    readerWriter: MultiplexedReaderWriter[F]
):
  def publicState: F[PublicP2PState] =
    writeRequest(
      MultiplexerIds.PeerStateRequest,
      ()
    ) *> allPortQueues.p2pState.createResponse
  def nextBlockAdoption: F[BlockId] =
    writeRequest(
      MultiplexerIds.BlockAdoptionRequest,
      ()
    ) *> allPortQueues.blockAdoptions.createResponse
  def nextTransactionNotification: F[TransactionId] =
    writeRequest(
      MultiplexerIds.TransactionNotificationRequest,
      ()
    ) *> allPortQueues.transactionAdoptions.createResponse
  def fetchHeader(id: BlockId): F[Option[BlockHeader]] =
    writeRequest(
      MultiplexerIds.HeaderRequest,
      id
    ) *> allPortQueues.headers.createResponse
  def fetchBody(id: BlockId): F[Option[BlockBody]] =
    writeRequest(
      MultiplexerIds.BodyRequest,
      id
    ) *> allPortQueues.bodies.createResponse
  def fetchTransaction(id: TransactionId): F[Option[Transaction]] =
    writeRequest(
      MultiplexerIds.TransactionRequest,
      id
    ) *> allPortQueues.transactions.createResponse
  def blockIdAtHeight(height: Height): F[Option[BlockId]] =
    writeRequest(
      MultiplexerIds.BlockIdAtHeightRequest,
      height
    ) *> allPortQueues.blockIdAtHeight.createResponse
  def ping(message: Bytes): F[Bytes] =
    writeRequest(
      MultiplexerIds.PingRequest,
      message
    ) *> allPortQueues.pingPong.createResponse
  def commonAncestor: F[BlockId] =
    for {
      localHeadId <- core.consensus.localChain.currentHead
      localHeader <- core.dataStores.headers.getOrRaise(localHeadId)
      intersection <- OptionT(
        narySearch[BlockId](
          height =>
            OptionT(core.consensus.localChain.blockIdAtHeight(height))
              .getOrRaise(new IllegalStateException("Local height not found")),
          blockIdAtHeight,
          Ratio(2, 3)
        )(1L, localHeader.height)
      ).getOrRaise(new IllegalStateException("Common ancestor not found"))
    } yield intersection

  def background: Stream[F, Unit] =
    readerStream.merge(portQueueStreams)

  private def readerStream =
    readerWriter.read
      .evalMap((port, bytes) =>
        bytes.byteAt(0) match {
          case 0 => processRequest(port, bytes.substring(1))
          case 1 => processResponse(port, bytes.substring(1))
          case _ =>
            Async[F]
              .raiseError(new IllegalArgumentException("Not RequestResponse"))
        }
      )

  private def portQueueStreams =
    Stream(
      allPortQueues.blockIdAtHeight.backgroundRequestProcessor(
        onPeerRequestedBlockIdAtHeight
      ),
      allPortQueues.headers.backgroundRequestProcessor(onPeerRequestedHeader),
      allPortQueues.bodies.backgroundRequestProcessor(onPeerRequestedBody),
      allPortQueues.transactions.backgroundRequestProcessor(
        onPeerRequestedTransaction
      ),
      allPortQueues.blockAdoptions.backgroundRequestProcessor((_) => onPeerRequestedBlockNotification()),
      allPortQueues.transactionAdoptions.backgroundRequestProcessor((_) => onPeerRequestedTransactionNotification()),
      allPortQueues.p2pState.backgroundRequestProcessor((_) => onPeerRequestedState()),
      allPortQueues.pingPong.backgroundRequestProcessor(onPeerRequestedPing)
    ).parJoinUnbounded

  private def processRequest(port: Int, data: Bytes) =
    port match {
      case MultiplexerIds.BlockIdAtHeightRequest =>
        allPortQueues.blockIdAtHeight.processRequest(data)
      case MultiplexerIds.HeaderRequest =>
        allPortQueues.headers.processRequest(data)
      case MultiplexerIds.BodyRequest =>
        allPortQueues.bodies.processRequest(data)
      case MultiplexerIds.BlockAdoptionRequest =>
        allPortQueues.blockAdoptions.processRequest(data)
      case MultiplexerIds.TransactionRequest =>
        allPortQueues.transactions.processRequest(data)
      case MultiplexerIds.TransactionNotificationRequest =>
        allPortQueues.transactionAdoptions.processRequest(data)
      case MultiplexerIds.PeerStateRequest =>
        allPortQueues.p2pState.processRequest(data)
      case MultiplexerIds.PingRequest =>
        allPortQueues.pingPong.processRequest(data)
      case _ =>
        Async[F].raiseError(new IllegalArgumentException(s"Invalid port=$port"))
    }

  private def processResponse(port: Int, data: Bytes): F[Unit] =
    port match {
      case MultiplexerIds.BlockIdAtHeightRequest =>
        allPortQueues.blockIdAtHeight.processResponse(data)
      case MultiplexerIds.HeaderRequest =>
        allPortQueues.headers.processResponse(data)
      case MultiplexerIds.BodyRequest =>
        allPortQueues.bodies.processResponse(data)
      case MultiplexerIds.BlockAdoptionRequest =>
        allPortQueues.blockAdoptions.processResponse(data)
      case MultiplexerIds.TransactionRequest =>
        allPortQueues.transactions.processResponse(data)
      case MultiplexerIds.TransactionNotificationRequest =>
        allPortQueues.transactionAdoptions.processResponse(data)
      case MultiplexerIds.PeerStateRequest =>
        allPortQueues.p2pState.processResponse(data)
      case MultiplexerIds.PingRequest =>
        allPortQueues.pingPong.processResponse(data)
      case _ =>
        Async[F].raiseError(new IllegalArgumentException(s"Invalid port=$port"))
    }

  private val ByteStringZero = ByteString.copyFrom(Array[Byte](0))
  private val ByteStringOne = ByteString.copyFrom(Array[Byte](1))

  private def writeRequest[Message: P2PEncodable](
      port: Int,
      message: Message
  ): F[Unit] =
    readerWriter.write(
      port,
      ByteStringZero.concat(P2PEncodable[Message].encodeP2P(message))
    )

  private def writeResponse[Message: P2PEncodable](
      port: Int,
      message: Message
  ): F[Unit] =
    readerWriter.write(
      port,
      ByteStringOne.concat(P2PEncodable[Message].encodeP2P(message))
    )

  private def onPeerRequestedBlockIdAtHeight(height: Height) =
    core.consensus.localChain
      .blockIdAtHeight(height)
      .flatMap(writeResponse(MultiplexerIds.BlockIdAtHeightRequest, _))

  private def onPeerRequestedHeader(id: BlockId) =
    core.dataStores.headers
      .get(id)
      .flatMap(writeResponse(MultiplexerIds.HeaderRequest, _))

  private def onPeerRequestedBody(id: BlockId) =
    core.dataStores.bodies
      .get(id)
      .flatMap(writeResponse(MultiplexerIds.BodyRequest, _))

  private def onPeerRequestedTransaction(id: TransactionId) =
    core.dataStores.transactions
      .get(id)
      .flatMap(writeResponse(MultiplexerIds.TransactionRequest, _))

  private def onPeerRequestedState() =
    manager.currentState.flatMap(
      writeResponse(MultiplexerIds.PeerStateRequest, _)
    )

  private def onPeerRequestedPing(message: Bytes) =
    writeResponse(MultiplexerIds.PingRequest, message)

  private def onPeerRequestedBlockNotification() =
    core.consensus.localChain.adoptions.head.compile.lastOrError
      .flatMap(writeResponse(MultiplexerIds.BlockAdoptionRequest, _))

  private def onPeerRequestedTransactionNotification() =
    core.ledger.mempool.changes
      .collectFirst { case MempoolChange.Added(tx) =>
        tx.id
      }
      .compile
      .lastOrError
      .flatMap(writeResponse(MultiplexerIds.TransactionNotificationRequest, _))

  private def narySearch[T](
      getLocal: Long => F[T],
      getRemote: Long => F[Option[T]],
      searchSpaceTarget: Ratio
  ): (Long, Long) => F[Option[T]] = {
    lazy val f: (Long, Long, Option[T]) => F[Option[T]] = (min, max, ifNone) =>
      Logger[F].debug(
        show"Recursing common ancestor search in bounds=($min, $max)"
      ) >>
        (min === max)
          .pure[F]
          .ifM(
            ifTrue = getLocal(min)
              .flatMap(localValue =>
                OptionT(getRemote(min))
                  .filter(_ == localValue)
                  .orElse(OptionT.fromOption[F](ifNone))
                  .value
              ),
            ifFalse = for {
              targetHeight <-
                (min + ((max - min) * searchSpaceTarget.toDouble).floor.round)
                  .pure[F]
              localValue <- getLocal(targetHeight)
              remoteValue <- getRemote(targetHeight)
              result <- remoteValue
                .filter(_ == localValue)
                .fold(f(min, targetHeight, ifNone))(remoteValue => f(targetHeight + 1, max, remoteValue.some))
            } yield result
          )
    (min, max) => f(min, max, None)
  }

case class AllPortQueues[F[_]](
    p2pState: PortQueues[F, Unit, PublicP2PState],
    blockAdoptions: PortQueues[F, Unit, BlockId],
    transactionAdoptions: PortQueues[F, Unit, TransactionId],
    pingPong: PortQueues[F, Bytes, Bytes],
    blockIdAtHeight: PortQueues[F, Height, Option[BlockId]],
    headers: PortQueues[F, BlockId, Option[BlockHeader]],
    bodies: PortQueues[F, BlockId, Option[BlockBody]],
    transactions: PortQueues[F, TransactionId, Option[Transaction]]
)

object AllPortQueues:
  def make[F[_]: Async]: Resource[F, AllPortQueues[F]] =
    (
      PortQueues.make[F, Unit, PublicP2PState],
      PortQueues.make[F, Unit, BlockId],
      PortQueues.make[F, Unit, TransactionId],
      PortQueues.make[F, Bytes, Bytes],
      PortQueues.make[F, Height, Option[BlockId]],
      PortQueues.make[F, BlockId, Option[BlockHeader]],
      PortQueues.make[F, BlockId, Option[BlockBody]],
      PortQueues.make[F, TransactionId, Option[Transaction]]
    ).mapN(AllPortQueues.apply[F])

case class PortQueues[F[_], Request, Response](
    requests: Queue[F, Request],
    responses: Queue[F, Deferred[F, Response]]
):
  def processRequest(request: Request): F[Unit] =
    requests.offer(request)
  def processResponse(response: Response)(using MonadThrow[F]): F[Unit] =
    OptionT(responses.tryTake)
      .getOrRaise(new IllegalStateException("Unexpected Response"))
      .flatMap(_.complete(response))
      .void
  def backgroundRequestProcessor(
      subProcessor: Request => F[Unit]
  )(using Async[F]): Stream[F, Unit] =
    Stream
      .fromQueueUnterminated(requests)
      .evalMap(subProcessor)
  def createResponse(using Async[F]): F[Response] =
    Deferred[F, Response].flatTap(responses.offer).flatMap(_.get)

object PortQueues:
  def make[F[_]: Async, Request, Response]: Resource[F, PortQueues[F, Request, Response]] =
    (
      Queue.unbounded[F, Request].toResource,
      Queue
        .unbounded[F, Deferred[F, Response]]
        .toResource
    )
      .mapN(PortQueues.apply)

object MultiplexerIds:
  val BlockIdAtHeightRequest = 10
  val HeaderRequest = 11
  val BodyRequest = 12
  val BlockAdoptionRequest = 13
  val TransactionRequest = 14
  val TransactionNotificationRequest = 15
  val PeerStateRequest = 16
  val PingRequest = 17

class PeerBlockchainHandler[F[_]: Async: Logger](
    core: BlockchainCore[F],
    interface: PeerBlockchainInterface[F],
    onPeerState: PublicP2PState => F[Unit]
):
  def handle: Stream[F, Unit] =
    pingPong.merge(peerState).mergeHaltR(start)

  private def pingPong =
    Stream
      .awakeEvery(5.seconds)
      .evalMap(_ => interface.ping(ByteString.EMPTY))
      .void

  private def peerState =
    Stream
      .awakeEvery(30.seconds)
      .evalMap(_ => interface.publicState)
      .evalMap(onPeerState)
      .void

  private def start = verifyGenesisAgreement ++ syncCheck

  private def verifyGenesisAgreement: Stream[F, Unit] =
    Stream.exec(
      for {
        remoteGenesisId <- OptionT(interface.blockIdAtHeight(Genesis.Height))
          .getOrRaise(new IllegalArgumentException("No Genesis"))
        localGenesisId <- core.consensus.localChain.genesis
        _ <- Async[F].raiseWhen(remoteGenesisId != localGenesisId)(
          new IllegalArgumentException("Genesis Mismatch")
        )
      } yield ()
    )

  private def syncCheck: Stream[F, Unit] =
    Stream.force(
      for {
        commonAncestorId <- interface.commonAncestor
        remoteHeadId <- OptionT(interface.blockIdAtHeight(0))
          .getOrRaise(new IllegalArgumentException("No Canonical Head"))
        remoteHeader <- OptionT(interface.fetchHeader(remoteHeadId))
          .getOrRaise(new IllegalArgumentException("No Canonical Head"))
        remoteHeaderAtHeightF = (height: Height) =>
          OptionT(interface.blockIdAtHeight(height))
            .flatMapF(interface.fetchHeader)
            .value
        commonAncestorHeader <- core.dataStores.headers.getOrRaise(
          commonAncestorId
        )
        localHeadId <- core.consensus.localChain.currentHead
        localHeader <- core.dataStores.headers.getOrRaise(localHeadId)
        localHeaderAtHeightF = (height: Height) =>
          OptionT(core.consensus.localChain.blockIdAtHeight(height))
            .flatMapF(core.dataStores.headers.get)
            .value
        chainSelectionResult <- core.consensus.chainSelection.compare(
          localHeader,
          remoteHeader,
          commonAncestorHeader,
          localHeaderAtHeightF,
          remoteHeaderAtHeightF
        )
        nextOperation <- chainSelectionResult match {
          case ChainSelectionOutcome.XStandard =>
            Logger[F].info(
              "Remote peer is up-to-date but local chain is better"
            ) >> waitForBetterBlock.pure[F]
          case ChainSelectionOutcome.YStandard =>
            Logger[F].info(
              "Local peer is up-to-date but remote chain is better"
            ) >> sync(commonAncestorHeader).pure[F]
          case ChainSelectionOutcome.XDensity =>
            Logger[F].info(
              "Remote peer is out-of-sync but local chain is better"
            ) >> waitForBetterBlock.pure[F]
          case ChainSelectionOutcome.YDensity =>
            Logger[F].info(
              "Local peer out-of-sync and remote chain is better"
            ) >> sync(commonAncestorHeader).pure[F]
        }
      } yield nextOperation
    )

  private def waitForBetterBlock: Stream[F, Unit] =
    Stream.force(
      interface.nextBlockAdoption.flatMap(blockId =>
        core.dataStores.headers
          .contains(blockId)
          .ifM(
            Logger[F].info(show"Ignoring known block id=$blockId") >>
              waitForBetterBlock.pure[F],
            OptionT(interface.fetchHeader(blockId))
              .getOrRaise(
                new IllegalArgumentException("Remote header not found")
              )
              .flatMap(remoteHeader =>
                core.consensus.localChain.currentHead.flatMap(currentHeadId =>
                  if (remoteHeader.parentHeaderId == currentHeadId)
                    fetchVerifyPersist(
                      remoteHeader
                    ) >> core.consensus.localChain.adopt(blockId) >>
                      waitForBetterBlock.pure[F]
                  else
                    syncCheck.pure[F]
                )
              )
          )
      )
    )

  private def sync(commonAncestor: BlockHeader): Stream[F, Unit] =
    Stream
      .unfoldEval((commonAncestor.height + 1, none[BlockId]))((h, lastProcessed) =>
        OptionT(interface.blockIdAtHeight(h))
          .semiflatMap(remoteId =>
            OptionT(interface.fetchHeader(remoteId))
              .getOrRaise(
                new IllegalArgumentException("Remote header not found")
              )
              .ensure(
                new IllegalStateException(
                  "Remote peer branched during syncing"
                )
              )(header => lastProcessed.forall(_ == header.parentHeaderId))
              .flatTap(fetchVerifyPersist)
              .as((h + 1, remoteId.some))
              .tupleLeft(remoteId)
          )
          .flatTapNone(
            lastProcessed.traverse(core.consensus.localChain.adopt)
          )
          .value
      )
      .void ++ waitForBetterBlock

  private def fetchVerifyPersist(header: BlockHeader): F[Unit] =
    for {
      _ <- Logger[F].info(show"Processing remote block id=${header.id}")
      _ <- core.consensus.headerValidation
        .validate(header)
        .leftMap(errors => new IllegalArgumentException(errors.head))
        .rethrowT
      _ <- core.dataStores.headers.put(header.id, header)
      _ <- core.blockIdTree.associate(header.id, header.parentHeaderId)
      body <- OptionT(interface.fetchBody(header.id))
        .getOrRaise(new IllegalArgumentException("Remote body not found"))
      transactions <- body.transactionIds.traverse(id =>
        OptionT(interface.fetchTransaction(id)).getOrRaise(
          new IllegalArgumentException("Remote transaction not found")
        )
      )
      _ <- transactions.traverse(transaction =>
        core.dataStores.transactions
          .contains(transaction.id)
          .ifM(
            ().pure[F],
            core.dataStores.transactions.put(transaction.id, transaction)
          )
      )
      _ <- core.ledger.bodyValidation
        .validate(
          body,
          TransactionValidationContext(
            header.parentHeaderId,
            header.height,
            header.slot
          )
        )
        .leftMap(errors => new IllegalArgumentException(errors.head))
        .rethrowT
    } yield ()
