package blockchain

import scala.collection.immutable.NumericRange
import scala.concurrent.duration.FiniteDuration

trait Clock[F[_]]:
  def slotLength: FiniteDuration
  def epochLength: Long
  def operationalPeriodLength: Long
  def globalSlot: F[Long]
  def globalTimestamp: F[Long]
  def timestampToSlot(timestamp: Long): F[Long]
  def slotToTimestampRange(slot: Long): F[NumericRange[Long]]
  def delayedUntilSlot(slot: Long): F[Unit]
