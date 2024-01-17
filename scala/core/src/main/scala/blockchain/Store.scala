package blockchain

import blockchain.codecs.{*, given}
import blockchain.models.*
import cats.{Monad, MonadThrow, Show}
import cats.data.OptionT
import cats.effect.{Async, Resource, Sync}
import cats.effect.implicits.*
import cats.implicits.*
import com.github.benmanes.caffeine.cache.Caffeine
import fs2.io.file.Path
import org.fusesource.leveldbjni.JniDBFactory
import org.iq80.leveldb
import org.iq80.leveldb.Options
import scalacache.Entry
import scalacache.caffeine.CaffeineCache
import scodec.bits.BitVector

trait Store[F[_], Key, T]:
  def get(key: Key): F[Option[T]]
  def contains(key: Key): F[Boolean]
  def put(key: Key, value: T): F[Unit]
  def remove(key: Key): F[Unit]
  def getOrRaise(key: Key)(using Show[Key])(using MonadThrow[F]): F[T] =
    OptionT(get(key)).getOrRaise(new NoSuchElementException(key.show))

case class DataStores[F[_]](
    blockIdTree: Store[F, BlockId, (Long, BlockId)],
    currentEventIds: Store[F, Byte, BlockId],
    headers: Store[F, BlockId, BlockHeader],
    bodies: Store[F, BlockId, BlockBody],
    transactions: Store[F, TransactionId, Transaction],
    spendableOutputs: Store[F, TransactionId, BitVector],
    accounts: Store[F, TransactionOutputReference, List[
      TransactionOutputReference
    ]],
    epochBoundaries: Store[F, Long, BlockId],
    activeStake: Store[F, Unit, Long],
    inactiveStake: Store[F, Unit, Long],
    stakers: Store[F, TransactionOutputReference, ActiveStaker],
    blockHeightIndex: Store[F, Long, BlockId],
    metadata: Store[F, String, Array[Byte]],
    transactionOutputs: Store[F, TransactionOutputReference, TransactionOutput]
) {
  def fetchFullBlock(blockId: BlockId)(using Monad[F]): F[Option[FullBlock]] =
    (
      OptionT(headers.get(blockId)),
      OptionT(bodies.get(blockId)).flatMap(body =>
        body.transactionIds.traverse(id => OptionT(transactions.get(id)))
      )
    ).mapN((header, transactions) =>
      FullBlock(header, FullBlockBody(transactions))
    ).value
}

object DataStores:
  def make[F[_]: Async](basePath: Path): Resource[F, DataStores[F]] =
    LevelDbStore
      .makeFactory[F]
      .flatMap(factory =>
        (
          makeCachedStore[F, BlockId, (Long, BlockId)](
            factory,
            basePath / "block-id-tree",
            8192
          ),
          makeCachedStore[F, Byte, BlockId](
            factory,
            basePath / "current-event-ids",
            32
          ),
          makeCachedStore[F, BlockId, BlockHeader](
            factory,
            basePath / "headers",
            4096
          ),
          makeCachedStore[F, BlockId, BlockBody](
            factory,
            basePath / "bodies",
            4096
          ),
          makeCachedStore[F, TransactionId, Transaction](
            factory,
            basePath / "transactions",
            4096
          ),
          makeCachedStore[F, TransactionId, BitVector](
            factory,
            basePath / "transaction-output-state",
            8192
          ),
          makeCachedStore[F, TransactionOutputReference, List[
            TransactionOutputReference
          ]](factory, basePath / "account-state", 128),
          makeCachedStore[F, Long, BlockId](
            factory,
            basePath / "epoch-boundaries",
            8
          ),
          makeCachedStore[F, Unit, Long](
            factory,
            basePath / "active-stake",
            1
          ),
          makeCachedStore[F, Unit, Long](
            factory,
            basePath / "inactive-stake",
            1
          ),
          makeCachedStore[F, TransactionOutputReference, ActiveStaker](
            factory,
            basePath / "stakers",
            256
          ),
          makeCachedStore[F, Long, BlockId](
            factory,
            basePath / "block-height-index",
            4096
          ),
          makeCachedStore[F, String, Array[Byte]](
            factory,
            basePath / "metadata",
            12
          )
        ).mapN(
          (
              parentChildTree,
              currentEventIds,
              headers,
              bodies,
              transactions,
              spendableOutputs,
              accounts,
              epochBoundaries,
              activeStake,
              inactiveStake,
              stakers,
              blockHeightIndex,
              metaData
          ) =>
            DataStores(
              parentChildTree,
              currentEventIds,
              headers,
              bodies,
              transactions,
              spendableOutputs,
              accounts,
              epochBoundaries,
              activeStake,
              inactiveStake,
              stakers,
              blockHeightIndex,
              metaData,
              new TransactionOutputStore(transactions)
            )
        )
      )

  private def makeCachedStore[F[
      _
  ]: Sync, Key: ArrayEncodable, Value: ArrayEncodable: ArrayDecodable](
      factory: JniDBFactory,
      dir: Path,
      cacheSize: Int
  ) =
    LevelDbStore
      .make[F, Key, Value](
        dir,
        factory
      )
      .flatMap(underlying =>
        CacheStore.make[F, Key, Value](underlying, cacheSize)
      )

class TransactionOutputStore[F[_]: MonadThrow](
    transactionStore: Store[F, TransactionId, Transaction]
) extends Store[F, TransactionOutputReference, TransactionOutput]:
  override def get(
      key: TransactionOutputReference
  ): F[Option[TransactionOutput]] =
    OptionT(transactionStore.get(key.transactionId))
      .subflatMap(_.outputs.lift(key.index))
      .value

  override def contains(key: TransactionOutputReference): F[Boolean] =
    OptionT(transactionStore.get(key.transactionId))
      .exists(_.outputs.length < key.index)

  override def put(
      key: TransactionOutputReference,
      value: TransactionOutput
  ): F[Unit] =
    MonadThrow[F].raiseError(new UnsupportedOperationException())

  override def remove(key: TransactionOutputReference): F[Unit] =
    MonadThrow[F].raiseError(new UnsupportedOperationException())

class EventIdGetterSetters[F[_]: MonadThrow](
    store: Store[F, Byte, BlockId]
):
  import EventIdGetterSetters.Indices

  val canonicalHead: EventIdGetterSetters.GetterSetter[F] =
    EventIdGetterSetters.GetterSetter.forByte(store)(
      Indices.CanonicalHead
    )

  val stakerData: EventIdGetterSetters.GetterSetter[F] =
    EventIdGetterSetters.GetterSetter.forByte(store)(
      Indices.ConsensusData
    )

  val epochBoundaries: EventIdGetterSetters.GetterSetter[F] =
    EventIdGetterSetters.GetterSetter.forByte(store)(
      Indices.EpochBoundaries
    )

  val blockHeightTree: EventIdGetterSetters.GetterSetter[F] =
    EventIdGetterSetters.GetterSetter.forByte(store)(
      Indices.BlockHeightTree
    )

  val transactionOutputState: EventIdGetterSetters.GetterSetter[F] =
    EventIdGetterSetters.GetterSetter.forByte(store)(
      Indices.TransactionOutputState
    )

  val accountState: EventIdGetterSetters.GetterSetter[F] =
    EventIdGetterSetters.GetterSetter.forByte(store)(Indices.AccountState)

  val mempool: EventIdGetterSetters.GetterSetter[F] =
    EventIdGetterSetters.GetterSetter.forByte(store)(Indices.Mempool)

  val epochData: EventIdGetterSetters.GetterSetter[F] =
    EventIdGetterSetters.GetterSetter.forByte(store)(Indices.EpochData)

  val registrationAccumulator: EventIdGetterSetters.GetterSetter[F] =
    EventIdGetterSetters.GetterSetter.forByte(store)(
      Indices.RegistrationAccumulator
    )

object EventIdGetterSetters:

  /** Captures a getter function and a setter function for a particular "Current
    * Event ID"
    * @param get
    *   a function which retrieves the current value/ID
    * @param set
    *   a function which sets the current value/ID
    */
  case class GetterSetter[F[_]](get: () => F[BlockId], set: BlockId => F[Unit])

  object GetterSetter:

    def forByte[F[_]: MonadThrow](
        store: Store[F, Byte, BlockId]
    )(byte: Byte): GetterSetter[F] =
      EventIdGetterSetters.GetterSetter(
        () => store.getOrRaise(byte),
        store.put(byte, _)
      )

  object Indices:
    val CanonicalHead: Byte = 0
    val ConsensusData: Byte = 1
    val EpochBoundaries: Byte = 2
    val BlockHeightTree: Byte = 3
    val TransactionOutputState: Byte = 4
    val AccountState: Byte = 5
    val Mempool: Byte = 6
    val EpochData: Byte = 7
    val RegistrationAccumulator: Byte = 8

class LevelDbStore[F[
    _
]: Sync, Key: ArrayEncodable, Value: ArrayEncodable: ArrayDecodable](
    instance: leveldb.DB
) extends Store[F, Key, Value]:
  override def get(key: Key): F[Option[Value]] =
    OptionT(
      Sync[F]
        .delay(key.encodeArray)
        .flatMap(k => useDb(_.get(k)))
        .map(Option(_))
    )
      .map(summon[ArrayDecodable[Value]].decodeFromArray)
      .value

  override def contains(key: Key): F[Boolean] =
    OptionT(
      Sync[F]
        .delay(key.encodeArray)
        .flatMap(k => useDb(_.get(k)))
        .map(Option(_))
    ).isDefined

  override def put(key: Key, value: Value): F[Unit] =
    Sync[F]
      .delay((key.encodeArray, value.encodeArray))
      .flatMap((key, value) => useDb(_.put(key, value)))
      .void

  override def remove(key: Key): F[Unit] =
    Sync[F]
      .delay(key.encodeArray)
      .flatMap(k => useDb(_.delete(k)))

  private def useDb[U](f: leveldb.DB => U) =
    Sync[F].blocking(f(instance))

object LevelDbStore:
  def makeFactory[F[_]: Sync] =
    Sync[F].delay(JniDBFactory.factory).toResource

  def make[F[
      _
  ]: Sync, Key: ArrayEncodable, Value: ArrayEncodable: ArrayDecodable](
      path: Path,
      factory: JniDBFactory
  ): Resource[F, LevelDbStore[F, Key, Value]] =
    Sync[F]
      .delay(factory.open(path.toNioPath.toFile, new Options))
      .toResource
      .map(new LevelDbStore[F, Key, Value](_))

class CacheStore[F[_]: Sync, Key, Value](
    underlying: Store[F, Key, Value],
    cache: CaffeineCache[F, Key, Option[Value]]
) extends Store[F, Key, Value]:
  override def get(key: Key): F[Option[Value]] =
    cache.cachingF(key)(ttl = None)(Sync[F].defer(underlying.get(key)))

  override def contains(key: Key): F[Boolean] =
    OptionT(get(key)).isDefined // TODO

  override def put(key: Key, value: Value): F[Unit] =
    cache.put(key)(value.some) *> underlying.put(key, value)

  override def remove(key: Key): F[Unit] =
    cache.remove(key) *> underlying.remove(key)

object CacheStore:
  def make[F[_]: Sync, Key, Value](
      underlying: Store[F, Key, Value],
      size: Int
  ): Resource[F, Store[F, Key, Value]] =
    CaffeineCache(
      Caffeine.newBuilder.maximumSize(size).build[Key, Entry[Option[Value]]]
    ).pure[F]
      .toResource
      .map(new CacheStore(underlying, _))
