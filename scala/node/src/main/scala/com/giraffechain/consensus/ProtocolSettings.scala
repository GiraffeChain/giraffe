package com.giraffechain.consensus

import cats.Show
import cats.implicits.showInterpolator
import com.giraffechain.utility.Ratio

import scala.concurrent.duration.{FiniteDuration, given}

case class ProtocolSettings(
    fEffective: Ratio,
    vrfLddCutoff: Int,
    vrfPrecision: Int,
    vrfBaselineDifficulty: Ratio,
    vrfAmplitude: Ratio,
    vrfSlotGap: Int,
    chainSelectionKLookback: Int,
    slotDuration: FiniteDuration
):

  val chainSelectionSWindow: Int =
    (Ratio(chainSelectionKLookback, 4) * fEffective.inverse).round.toInt

  val epochLength: Int =
    (Ratio(chainSelectionKLookback * 3) * fEffective.inverse).round.toInt

  require(epochLength % 3L == 0, s"Epoch length=$epochLength must be divisible by 3")

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
      show" epochLength=$epochLength slots" +
      show")"

  def merge(map: Map[String, String]): ProtocolSettings =
    map.foldLeft(this)(_.withSetting.apply.tupled(_))

  def withSetting(name: String, value: String): ProtocolSettings =
    name match {
      case "f-effective"                => copy(fEffective = parseRational(value))
      case "vrf-ldd-cutoff"             => copy(vrfLddCutoff = value.toInt)
      case "vrf-precision"              => copy(vrfPrecision = value.toInt)
      case "vrf-baseline-difficulty"    => copy(vrfBaselineDifficulty = parseRational(value))
      case "vrf-amplitude"              => copy(vrfAmplitude = parseRational(value))
      case "vrf-slot-gap"               => copy(vrfSlotGap = value.toInt)
      case "chain-selection-k-lookback" => copy(chainSelectionKLookback = value.toInt)
      case "slot-duration-ms"           => copy(slotDuration = value.toLong.milli)
      case _                            => throw IllegalArgumentException(name)
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
      "slot-duration-ms" -> slotDuration.toMillis.toString
    )

object ProtocolSettings:
  val Default: ProtocolSettings = ProtocolSettings(
    fEffective = Ratio(3, 25),
    vrfLddCutoff = 18,
    vrfPrecision = 40,
    vrfBaselineDifficulty = Ratio(1, 20),
    vrfAmplitude = Ratio(6, 15),
    vrfSlotGap = 2,
    chainSelectionKLookback = 576,
    slotDuration = 1000.milli
  )

  val ShortEpochs: ProtocolSettings = ProtocolSettings(
    fEffective = Ratio(1),
    vrfLddCutoff = 12,
    vrfPrecision = 40,
    vrfBaselineDifficulty = Ratio(1, 2),
    vrfAmplitude = Ratio(9, 10),
    vrfSlotGap = 1,
    chainSelectionKLookback = 9,
    slotDuration = 1000.milli
  )

  given Show[ProtocolSettings] = Show.fromToString
