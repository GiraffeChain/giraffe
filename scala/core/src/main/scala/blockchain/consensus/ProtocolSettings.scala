package blockchain.consensus

import blockchain.utility.Ratio
import cats.implicits.showInterpolator

import scala.concurrent.duration.{FiniteDuration, given}

case class ProtocolSettings(
    fEffective: Ratio,
    vrfLddCutoff: Int,
    vrfPrecision: Int,
    vrfBaselineDifficulty: Ratio,
    vrfAmplitude: Ratio,
    vrfSlotGap: Int,
    chainSelectionKLookback: Int,
    slotDuration: FiniteDuration,
    operationalPeriodsPerEpoch: Int,
    kesKeyHours: Int,
    kesKeyMinutes: Int
):

  val chainSelectionSWindow: Int =
    (Ratio(chainSelectionKLookback, 4) * fEffective.inverse).round.toInt

  val epochLength: Int =
    (Ratio(chainSelectionKLookback * 3) * fEffective.inverse).round.toInt

  val operationalPeriodLength: Int =
    epochLength / operationalPeriodsPerEpoch

  val kesTreeHeight: TreeHeight =
    TreeHeight(kesKeyHours, kesKeyMinutes)

  require(epochLength % 3L == 0, s"Epoch length=$epochLength must be divisible by 3")
  require(
    epochLength % operationalPeriodsPerEpoch == 0,
    s"Epoch length=$epochLength must be divisible by $operationalPeriodsPerEpoch"
  )

  override def toString: String =
    show"ProtocolSettings(fEffective=$fEffective, vrfLddCutoff=$vrfLddCutoff, vrfPrecision=$vrfPrecision, vrfBaselineDifficulty=$vrfBaselineDifficulty, vrfAmplitude=$vrfAmplitude, vrfSlotGap=$vrfSlotGap, kLookback=$chainSelectionKLookback, slotDuration=$slotDuration, operationalPeriodsPerEpoch=$operationalPeriodsPerEpoch, kesHeight=($kesKeyHours, $kesKeyMinutes), operationalPeriodLength=$operationalPeriodLength, epochLength=$epochLength)"

  def merge(map: Map[String, String]): ProtocolSettings =
    map.foldLeft(this)(_.withSetting.apply.tupled(_))

  def withSetting(name: String, value: String): ProtocolSettings =
    name match {
      case "f-effective"                   => copy(fEffective = parseRational(value))
      case "vrf-ldd-cutoff"                => copy(vrfLddCutoff = value.toInt)
      case "vrf-precision"                 => copy(vrfPrecision = value.toInt)
      case "vrf-baseline-difficulty"       => copy(vrfBaselineDifficulty = parseRational(value))
      case "vrf-amplitude"                 => copy(vrfAmplitude = parseRational(value))
      case "vrf-slot-gap"                  => copy(vrfSlotGap = value.toInt)
      case "chain-selection-k-lookback"    => copy(chainSelectionKLookback = value.toInt)
      case "slot-duration-ms"              => copy(slotDuration = value.toLong.milli)
      case "operational-periods-per-epoch" => copy(operationalPeriodsPerEpoch = value.toInt)
      case "kes-key-hours"                 => copy(kesKeyHours = value.toInt)
      case "kes-key-minutes"               => copy(kesKeyMinutes = value.toInt)
      case _                               => throw IllegalArgumentException(name)
    }
  private def parseRational(value: String): Ratio =
    value.split('/') match {
      case Array(numerator)              => Ratio(BigInt(numerator))
      case Array(numerator, denominator) => Ratio(BigInt(numerator), BigInt(denominator))
      case _                             => throw IllegalArgumentException(value)
    }

object ProtocolSettings:

  val Default: ProtocolSettings = ProtocolSettings(
    fEffective = Ratio(1, 25),
    vrfLddCutoff = 50,
    vrfPrecision = 40,
    vrfBaselineDifficulty = Ratio(1, 60),
    vrfAmplitude = Ratio(1, 8),
    vrfSlotGap = 3,
    chainSelectionKLookback = 576,
    slotDuration = 1000.milli,
    operationalPeriodsPerEpoch = 12,
    kesKeyHours = 5,
    kesKeyMinutes = 5
  )

case class TreeHeight(hours: Int, minutes: Int) {
  def asTuple: (Int, Int) = (hours, minutes)
}
