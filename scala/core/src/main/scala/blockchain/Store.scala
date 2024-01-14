package blockchain

import blockchain.models.*
import cats.{MonadThrow, Show}
import cats.data.OptionT
import cats.implicits.*

trait Store[F[_], Key, T]:
  def get(key: Key): F[Option[T]]
  def contains(key: Key): F[Boolean]
  def put(key: Key, value: T): F[Unit]
  def remove(key: Key): F[Unit]
  def getOrRaise(key: Key)(using Show[Key])(using MonadThrow[F]): F[T] =
    OptionT(get(key)).getOrRaise(new NoSuchElementException(key.show))

case class DataStores[F[_]](
    parentChildTree: Store[F, BlockId, (Long, BlockId)],
    currentEventIds: Store[F, Byte, BlockId],
    headers: Store[F, BlockId, BlockHeader],
    bodies: Store[F, BlockId, BlockBody],
    transactions: Store[F, TransactionId, Transaction],
    spendableOutputs: Store[F, TransactionId, Array[Boolean]],
    epochBoundaries: Store[F, Long, BlockId],
    activeStake: Store[F, Unit, Long],
    inactiveStake: Store[F, Unit, Long],
    stakers: Store[F, TransactionOutputReference, ActiveStaker],
    blockHeightIndex: Store[F, Long, BlockId],
    metadata: Store[F, String, Array[Byte]]
)

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

  val boxState: EventIdGetterSetters.GetterSetter[F] =
    EventIdGetterSetters.GetterSetter.forByte(store)(Indices.BoxState)

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
    val BoxState: Byte = 4
    val Mempool: Byte = 5
    val EpochData: Byte = 6
    val RegistrationAccumulator: Byte = 7
