package blockchain.consensus

import blockchain.utility.Ratio
import cats.Show
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
    show"ProtocolSettings(" +
      show"fEffective=$fEffective," +
      show" vrfLddCutoff=$vrfLddCutoff," +
      show" vrfPrecision=$vrfPrecision," +
      show" vrfBaselineDifficulty=$vrfBaselineDifficulty," +
      show" vrfAmplitude=$vrfAmplitude," +
      show" vrfSlotGap=$vrfSlotGap," +
      show" kLookback=$chainSelectionKLookback," +
      show" slotDuration=$slotDuration," +
      show" operationalPeriodsPerEpoch=$operationalPeriodsPerEpoch," +
      show" kesHeight=($kesKeyHours, $kesKeyMinutes)," +
      show" operationalPeriodLength=$operationalPeriodLength slots," +
      show" epochLength=$epochLength slots" +
      show")"

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
  def toMap: Map[String, String] =
    Map(
      "f-effective" -> fEffective.toString,
      "vrf-ldd-cutoff" -> vrfLddCutoff.toString,
      "vrf-precision" -> vrfPrecision.toString,
      "vrf-baseline-difficulty" -> vrfBaselineDifficulty.toString,
      "vrf-amplitude" -> vrfAmplitude.toString,
      "vrf-slot-gap" -> vrfSlotGap.toString,
      "chain-selection-k-lookback" -> chainSelectionKLookback.toString,
      "slot-duration-ms" -> slotDuration.toMillis.toString,
      "operational-periods-per-epoch" -> operationalPeriodsPerEpoch.toString,
      "kes-key-hours" -> kesKeyHours.toString,
      "kes-key-minutes" -> kesKeyMinutes.toString
    )

object ProtocolSettings:

  val Default: ProtocolSettings = ProtocolSettings(
    fEffective = Ratio(3, 25),
    vrfLddCutoff = 18,
    vrfPrecision = 40,
    vrfBaselineDifficulty = Ratio(1, 20),
    vrfAmplitude = Ratio(1, 2),
    vrfSlotGap = 1,
    chainSelectionKLookback = 576,
    slotDuration = 3000.milli,
    operationalPeriodsPerEpoch = 12,
    kesKeyHours = 5,
    kesKeyMinutes = 5
  )

  given Show[ProtocolSettings] = Show.fromToString

case class TreeHeight(hours: Int, minutes: Int) {
  def asTuple: (Int, Int) = (hours, minutes)
}
