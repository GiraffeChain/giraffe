package blockchain.utility

import cats.Show
import cats.effect.{Resource, Sync}
import cats.implicits.*
import com.github.benmanes.caffeine.cache.Caffeine
import scalacache.Entry
import scalacache.caffeine.CaffeineCache

import scala.annotation.tailrec

case class Ratio(
    numerator: BigInt,
    denominator: BigInt,
    greatestCommonDenominator: BigInt
) {

  override def toString(): String =
    numerator.toString + (if (denominator != 1) ("/" + denominator) else "")

  override def equals(that: Any): Boolean =
    that.asInstanceOf[Matchable] match {
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

trait Log1P[F[_]]:
  def evaluate(x: Ratio): F[Ratio]

object Log1P:
  def make[F[_]: Sync](
      maxIterations: Int = 10_000,
      precision: Int = 8
  ): Resource[F, Log1PImpl[F]] =
    Resource.pure(new Log1PImpl[F](maxIterations, precision))
  def makeCached[F[_]: Sync](base: Log1P[F]): Resource[F, Log1P[F]] =
    Resource
      .pure(
        CaffeineCache[F, Ratio, Ratio](
          Caffeine.newBuilder
            .maximumSize(512)
            .build[Ratio, Entry[Ratio]]()
        )
      )
      .map(cache =>
        (x: Ratio) =>
          cache.cachingF(x)(ttl = None)(Sync[F].defer(base.evaluate(x)))
      )

class Log1PImpl[F[_]: Sync](maxIterations: Int, precision: Int)
    extends Log1P[F]:
  override def evaluate(x: Ratio): F[Ratio] =
    def a(j: Int): Ratio = j match {
      case 0 => Ratio.Zero
      case 1 => x
      case _ => Ratio(j - 1) * Ratio(j - 1) * x
    }
    def b(j: Int): Ratio = j match {
      case 0 => Ratio.Zero
      case 1 => Ratio.One
      case _ => Ratio(j) - Ratio(j - 1) * x
    }
    Sync[F]
      .delay(Lentz.modifiedLentzMethod(maxIterations, precision, a, b))
      .map(_._1)

trait Exp[F[_]]:
  def evaluate(x: Ratio): F[Ratio]

object Exp:
  def make[F[_]: Sync](
      maxIterations: Int = 10_000,
      precision: Int = 38
  ): Resource[F, Exp[F]] =
    Resource.pure(new ExpImpl(maxIterations, precision))

class ExpImpl[F[_]: Sync](maxIterations: Int, precision: Int) extends Exp[F]:
  def evaluate(x: Ratio): F[Ratio] =
    Sync[F].delay {
      def a(j: Int): Ratio = j match {
        case 0 => Ratio.Zero
        case 1 => Ratio.One
        case 2 => Ratio.NegativeOne * x
        case _ => Ratio(-j + 2) * x
      }
      def b(j: Int): Ratio = j match {
        case 0 => Ratio.Zero
        case 1 => Ratio.One
        case _ => Ratio(j - 1) + x
      }
      if (x == Ratio.Zero) Ratio.One
      else Lentz.modifiedLentzMethod(maxIterations, precision, a, b)._1
    }

object Lentz:

  /** Implementation of modified Lentz's method from "Numerical Recipes in
    * Fortran 77" Second Edition Section 5.2 William H. Press, Saul A.
    * Teukolsky, William T. Vetterling, and Brian P. Flannery. 1992. Numerical
    * recipes in FORTRAN (2nd ed.): the art of scientific computing. Cambridge
    * University Press, USA.
    *
    * The numerical technique uses a set of coefficients to calculate a nested
    * fraction iteratively, avoiding nested recursion and providing a much more
    * performant algorithm
    * @param maxIterations
    *   maximum number of iterations
    * @param precision
    *   desired precision
    * @param a
    *   a coefficients that map integers to ratios
    * @param b
    *   b coefficients that map integers to ratios
    * @return
    *   a tuple containing: ratio approximating the nested fraction, false if
    *   method converged true otherwise, number of iterations
    */
  def modifiedLentzMethod(
      maxIterations: Int,
      precision: Int,
      a: Int => Ratio,
      b: Int => Ratio
  ): (Ratio, Boolean, Int) = {
    val bigFactor = BigInt(10).pow(precision + 10)
    val tinyFactor = Ratio(1, bigFactor)
    val truncationError: Ratio = Ratio(1, BigInt(10).pow(precision + 1))
    var fj: Ratio =
      if (b(0) == Ratio.Zero) tinyFactor
      else b(0)
    var cj: Ratio = fj
    var dj: Ratio = Ratio.Zero
    var deltaj = Ratio.One
    var error: Boolean = true
    def loop(j: Int): Unit = {
      dj = b(j) + a(j) * dj
      if (dj == Ratio.Zero) dj = tinyFactor
      cj = b(j) + a(j) / cj
      if (cj == Ratio.Zero) cj = tinyFactor
      dj = Ratio(dj.denominator, dj.numerator)
      deltaj = cj * dj
      fj = fj * deltaj
      error = j match {
        case _ if j > 1 => (deltaj - Ratio.One).abs > truncationError
        case _          => true
      }
    }
    var j = 1
    while (j < maxIterations + 1 && error) {
      loop(j)
      j = j + 1
    }
    if (fj.denominator < 0) fj = Ratio(-fj.numerator, -fj.denominator)
    (fj, error, j)
  }
