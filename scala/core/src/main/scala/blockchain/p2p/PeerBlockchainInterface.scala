package blockchain.p2p

import blockchain.codecs.{Codecs, P2PEncodable, given}
import blockchain.ledger.MempoolChange
import blockchain.models.*
import blockchain.utility.Ratio
import blockchain.{BlockchainCore, Bytes, Height}
import cats.data.OptionT
import cats.effect.Async
import cats.effect.implicits.*
import cats.effect.kernel.Resource
import cats.effect.std.Queue
import cats.implicits.*
import fs2.Stream
import org.typelevel.log4cats.Logger

import scala.concurrent.duration.*

class PeerBlockchainInterface[F[_]: Async: Logger](
    core: BlockchainCore[F],
    manager: PeersManager[F],
    allPortQueues: AllPortQueues[F],
    readerWriter: MultiplexedReaderWriter[F],
    cache: PeerCache[F]
):
  def publicState: F[PublicP2PState] =
    writeRequest(MultiplexerIds.PeerStateRequest, ()) *>
      allPortQueues.p2pState.createResponse.withDefaultTimeout
  def nextBlockAdoption: F[BlockId] =
    cache.remoteBlockAdoptions.take
  def nextTransactionNotification: F[TransactionId] =
    cache.remoteTransactionAdoptions.take
  def fetchHeader(id: BlockId): F[Option[BlockHeader]] =
    writeRequest(MultiplexerIds.HeaderRequest, id) *>
      OptionT(allPortQueues.headers.createResponse.withDefaultTimeout)
        .map(_.withEmbeddedId)
        .ensure(new IllegalArgumentException("Header ID Mismatch"))(_.id == id)
        .value
  def fetchBody(id: BlockId): F[Option[BlockBody]] =
    writeRequest(MultiplexerIds.BodyRequest, id) *>
      allPortQueues.bodies.createResponse.withDefaultTimeout
  def fetchTransaction(id: TransactionId): F[Option[Transaction]] =
    writeRequest(MultiplexerIds.TransactionRequest, id) *>
      OptionT(allPortQueues.transactions.createResponse.withDefaultTimeout)
        .map(_.withEmbeddedId)
        .ensure(new IllegalArgumentException("Transaction ID Mismatch"))(_.id == id)
        .value
  def blockIdAtHeight(height: Height): F[Option[BlockId]] =
    writeRequest(MultiplexerIds.BlockIdAtHeightRequest, height) *>
      allPortQueues.blockIdAtHeight.createResponse.withDefaultTimeout
  def ping(message: Bytes): F[Bytes] =
    writeRequest(MultiplexerIds.PingRequest, message) *>
      allPortQueues.pingPong.createResponse.withDefaultTimeout
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
        )(1L, localHeader.height).timeout(8.seconds)
      ).getOrRaise(new IllegalStateException("Common ancestor not found"))
    } yield intersection

  def background: Stream[F, Unit] =
    readerStream.merge(portQueueStreams).merge(cacheStreams)

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

  extension [A](fa: F[A]) def withDefaultTimeout: F[A] = fa.timeout(3.seconds)

  private def portQueueStreams =
    Stream(
      allPortQueues.blockIdAtHeight.backgroundRequestProcessor(onPeerRequestedBlockIdAtHeight),
      allPortQueues.headers.backgroundRequestProcessor(onPeerRequestedHeader),
      allPortQueues.bodies.backgroundRequestProcessor(onPeerRequestedBody),
      allPortQueues.transactions.backgroundRequestProcessor(onPeerRequestedTransaction),
      allPortQueues.blockAdoptions.backgroundRequestProcessor(_ => onPeerRequestedBlockNotification()),
      allPortQueues.transactionAdoptions.backgroundRequestProcessor(_ => onPeerRequestedTransactionNotification()),
      allPortQueues.p2pState.backgroundRequestProcessor(_ => onPeerRequestedState()),
      allPortQueues.pingPong.backgroundRequestProcessor(onPeerRequestedPing)
    ).parJoinUnbounded

  private def cacheStreams =
    Stream(
      core.consensus.localChain.adoptions.enqueueUnterminated(cache.localBlockAdoptions).void,
      core.ledger.mempool.changes
        .collect { case MempoolChange.Added(transaction) => transaction.id }
        .enqueueUnterminated(cache.localTransactionAdoptions)
        .void,
      Stream
        .repeatEval(
          writeRequest(MultiplexerIds.BlockAdoptionRequest, ()) *> allPortQueues.blockAdoptions.createResponse
        )
        .enqueueUnterminated(cache.remoteBlockAdoptions),
      Stream
        .repeatEval(
          writeRequest(
            MultiplexerIds.TransactionNotificationRequest,
            ()
          ) *> allPortQueues.transactionAdoptions.createResponse
        )
        .enqueueUnterminated(cache.remoteTransactionAdoptions)
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

  private def writeRequest[Message: P2PEncodable](
      port: Int,
      message: Message
  ): F[Unit] =
    readerWriter.write(port, Codecs.ZeroBS.concat(P2PEncodable[Message].encodeP2P(message)))

  private def writeResponse[Message: P2PEncodable](
      port: Int,
      message: Message
  ): F[Unit] =
    readerWriter.write(port, Codecs.OneBS.concat(P2PEncodable[Message].encodeP2P(message)))

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
    cache.localBlockAdoptions.take
      .flatMap(writeResponse(MultiplexerIds.BlockAdoptionRequest, _))

  private def onPeerRequestedTransactionNotification() =
    cache.localTransactionAdoptions.take
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

class PeerCache[F[_]](
    val localBlockAdoptions: Queue[F, BlockId],
    val localTransactionAdoptions: Queue[F, TransactionId],
    val remoteBlockAdoptions: Queue[F, BlockId],
    val remoteTransactionAdoptions: Queue[F, TransactionId]
)
object PeerCache:
  def make[F[_]: Async]: Resource[F, PeerCache[F]] =
    (
      Queue.circularBuffer[F, BlockId](32),
      Queue.circularBuffer[F, TransactionId](32),
      Queue.circularBuffer[F, BlockId](32),
      Queue.circularBuffer[F, TransactionId](32)
    )
      .mapN(new PeerCache[F](_, _, _, _))
      .toResource
