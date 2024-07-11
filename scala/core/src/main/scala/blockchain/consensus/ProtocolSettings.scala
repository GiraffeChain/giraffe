package blockchain.consensus

import blockchain.utility.Ratio
import cats.implicits.showInterpolator

import scala.concurrent.duration.{Duration, FiniteDuration, given}

case class ProtocolSettings(
    fEffective: Ratio,
    vrfLddCutoff: Int,
    vrfPrecision: Int,
    vrfBaselineDifficulty: Ratio,
    vrfAmplitude: Ratio,
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

  override def toString: String =
    show"ProtocolSettings(fEffective=$fEffective, vrfLddCutoff=$vrfLddCutoff, vrfPrecision=$vrfPrecision, vrfBaselineDifficulty=$vrfBaselineDifficulty, vrfAmplitude=$vrfAmplitude, kLookback=$chainSelectionKLookback, slotDuration=$slotDuration, operationalPeriodsPerEpoch=$operationalPeriodsPerEpoch, kesHeight=($kesKeyHours, $kesKeyMinutes), operationalPeriodLength=$operationalPeriodLength, epochLength=$epochLength)"

  def merge(map: Map[String, String]): ProtocolSettings =
    map.foldLeft(this)(_.withSetting.apply.tupled(_))

  def withSetting(name: String, value: String): ProtocolSettings =
    name match {
      case "f-effective"                   => copy(fEffective = parseRational(value))
      case "vrf-ldd-cutoff"                => copy(vrfLddCutoff = value.toInt)
      case "vrf-precision"                 => copy(vrfPrecision = value.toInt)
      case "vrf-baseline-difficulty"       => copy(vrfBaselineDifficulty = parseRational(value))
      case "vrf-amplitude"                 => copy(vrfAmplitude = parseRational(value))
      case "chain-selection-k-lookback"    => copy(chainSelectionKLookback = value.toInt)
      case "slot-duration-ms"              => copy(slotDuration = Duration(value).asInstanceOf[FiniteDuration])
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

  val Default = ProtocolSettings(
    fEffective = Ratio(3, 25),
    vrfLddCutoff = 15,
    vrfPrecision = 40,
    vrfBaselineDifficulty = Ratio(1, 20),
    vrfAmplitude = Ratio(1, 2),
    chainSelectionKLookback = 81, // 5184
    slotDuration = 1000.milli,
    operationalPeriodsPerEpoch = 25,
    kesKeyHours = 9,
    kesKeyMinutes = 9
  )

case class TreeHeight(hours: Int, minutes: Int)
