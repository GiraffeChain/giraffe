package blockchain.p2p

import blockchain.codecs.{P2PEncodable, given}
import blockchain.ledger.MempoolChange
import blockchain.models.*
import blockchain.utility.Ratio
import blockchain.{BlockchainCore, Bytes, Height}
import cats.data.OptionT
import cats.effect.Async
import cats.implicits.*
import cats.effect.implicits.*
import com.google.protobuf.ByteString
import fs2.Stream
import org.typelevel.log4cats.Logger

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
        allPortQueues.blockAdoptions.processRequest(())
      case MultiplexerIds.TransactionRequest =>
        allPortQueues.transactions.processRequest(data)
      case MultiplexerIds.TransactionNotificationRequest =>
        allPortQueues.transactionAdoptions.processRequest(())
      case MultiplexerIds.PeerStateRequest =>
        allPortQueues.p2pState.processRequest(())
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
