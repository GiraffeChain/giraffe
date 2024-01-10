package blockchain.utility

import cats.Show

import scala.annotation.tailrec

case class Ratio(
    numerator: BigInt,
    denominator: BigInt,
    greatestCommonDenominator: BigInt
) {

  override def toString(): String =
    numerator.toString + (if (denominator != 1) ("/" + denominator) else "")

  override def equals(that: Any): Boolean =
    that match {
      case that: Ratio =>
        numerator == that.numerator && denominator == that.denominator
      case _ => false
    }

  override def hashCode: Int =
    41 * numerator.hashCode() + denominator.hashCode()

  def inverse: Ratio =
    Ratio(denominator, numerator)

  def abs: Ratio =
    Ratio(
      numerator match {
        case num if num < 0 => -num
        case num            => num
      },
      denominator match {
        case den if den < 0 => -den
        case den            => den
      }
    )

  def pow(n: Int) =
    Ratio(
      numerator.pow(n),
      denominator.pow(n)
    )

  def - =
    Ratio(
      -numerator,
      denominator
    )

  def *(that: Int) =
    Ratio(
      numerator * that,
      denominator
    )

  def /(that: Int) =
    Ratio(
      numerator,
      denominator * that
    )

  def *(that: Long) =
    Ratio(
      numerator * that,
      denominator
    )

  def *(that: BigInt) =
    Ratio(
      numerator * that,
      denominator
    )

  def /(that: Long) =
    Ratio(
      numerator,
      denominator * that
    )

  def +(that: Ratio): Ratio =
    Ratio(
      numerator * that.denominator + that.numerator * denominator,
      denominator * that.denominator
    )

  def -(that: Ratio): Ratio =
    Ratio(
      numerator * that.denominator - that.numerator * denominator,
      denominator * that.denominator
    )

  def *(that: Ratio): Ratio =
    Ratio(numerator * that.numerator, denominator * that.denominator)

  def /(that: Ratio): Ratio =
    Ratio(numerator * that.denominator, denominator * that.numerator)

  def <(that: Ratio): Boolean =
    that.denominator * numerator < that.numerator * denominator

  def >(that: Ratio): Boolean =
    that.denominator * numerator > that.numerator * denominator

  def <=(that: Ratio): Boolean =
    that.denominator * numerator <= that.numerator * denominator

  def >=(that: Ratio): Boolean =
    that.denominator * numerator >= that.numerator * denominator

  def toBigDecimal: BigDecimal =
    BigDecimal(numerator) / BigDecimal(denominator)

  def toDouble: Double = this.toBigDecimal.toDouble

  def round: BigInt =
    if (numerator.abs > denominator.abs) {
      numerator.abs / denominator.abs
    } else {
      BigInt(1)
    }
}

object Ratio {

  val One: Ratio = Ratio(1)

  val Zero: Ratio = Ratio(0)

  val NegativeOne: Ratio = Ratio(-1)

  def apply(n: BigInt): Ratio = apply(n, 1: BigInt)

  def apply(n: BigInt, d: BigInt): Ratio = {
    val gcdVal = gcd(n, d)
    Ratio(n / gcdVal, d / gcdVal, gcdVal)
  }

  def apply(i: Int): Ratio = Ratio(i: BigInt, 1: BigInt)
  def apply(n: Int, d: Int): Ratio = apply(n: BigInt, d: BigInt)

  def apply(double: Double, prec: Int): Ratio = {
    val d = BigInt(10).pow(prec)
    val n = (BigDecimal(double).setScale(
      prec,
      BigDecimal.RoundingMode.DOWN
    ) * BigDecimal(d)).toBigInt
    new Ratio(n, d, gcd(n, d))
  }

  @tailrec
  private def gcd(a: BigInt, b: BigInt): BigInt =
    if (b == 0) a else gcd(b, a % b)

  implicit val show: Show[Ratio] = Show.fromToString
}
