package blockchain

import blockchain.Clock.SlotBoundary
import blockchain.consensus.ProtocolSettings
import cats.Applicative
import cats.effect.{Async, Resource}
import cats.implicits.*

import java.time.Instant
import scala.collection.immutable.NumericRange
import scala.concurrent.duration.{Duration, FiniteDuration}

trait Clock[F[_]]:
  def slotLength: FiniteDuration
  def epochLength: Long
  def globalSlot: F[Long]
  def globalTimestamp: F[Long]
  def timestampToSlot(timestamp: Long): F[Long]
  def slotToTimestampRange(slot: Long): F[Clock.SlotBoundary]
  def delayedUntilSlot(slot: Long): F[Unit]

  def epochOf(slot: Slot)(using fApplicative: Applicative[F]): F[Epoch] =
    if (slot == 0L) (-1L).pure[F]
    else if (slot < 0L) (-2L).pure[F]
    else ((slot - 1) / epochLength).pure[F]

  def epochRange(
      epoch: Epoch
  )(using fApplicative: Applicative[F]): F[Clock.SlotBoundary] =
    if (epoch == -1L) (0L to 0L).pure[F]
    else if (epoch < -1L) (-1L to -1L).pure[F]
    else ((epoch * epochLength + 1) to (epoch + 1) * epochLength).pure[F]

object Clock:
  type SlotBoundary = NumericRange[Long]

  def make[F[_]: Async](
      protocolSettings: ProtocolSettings,
      genesisTimestamp: Instant
  ): Resource[F, Clock[F]] =
    Resource.pure(
      new ClockImpl[F](
        protocolSettings.slotDuration,
        protocolSettings.epochLength,
        genesisTimestamp
      )
    )

class ClockImpl[F[_]: Async](
    val slotLength: FiniteDuration,
    val epochLength: Long,
    genesisTimestamp: Instant
) extends Clock[F]:
  private val startTime = genesisTimestamp.toEpochMilli

  override def globalSlot: F[Slot] =
    globalTimestamp.flatMap(timestampToSlot)

  override def globalTimestamp: F[Timestamp] =
    Async[F].delay(System.currentTimeMillis())

  override def timestampToSlot(timestamp: Slot): F[Slot] =
    Async[F].delay((timestamp - startTime) / slotLength.toMillis)

  override def slotToTimestampRange(slot: Slot): F[SlotBoundary] =
    Async[F].delay {
      if (slot == 0L) (0L to startTime)
      else {
        val startTimestamp = startTime + (slot * slotLength.toMillis)
        val endTimestamp = startTimestamp + (slotLength.toMillis - 1)
        NumericRange.inclusive(startTimestamp, endTimestamp, 1L)
      }
    }

  override def delayedUntilSlot(slot: Slot): F[Unit] =
    globalSlot
      .map(currentSlot => slotLength * (slot - currentSlot))
      .flatMap(delayedFor)

  private def delayedFor(duration: FiniteDuration): F[Unit] =
    if (duration < Duration.Zero) Applicative[F].unit
    else Async[F].sleep(duration)
