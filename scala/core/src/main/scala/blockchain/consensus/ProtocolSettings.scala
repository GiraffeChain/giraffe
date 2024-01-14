package blockchain.consensus

import blockchain.models.BlockHeader
import blockchain.utility.Ratio
import cats.implicits.showInterpolator

import scala.concurrent.duration.{FiniteDuration, given}

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

  def merge(map: Map[String, String]): ProtocolSettings = this // TODO

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
