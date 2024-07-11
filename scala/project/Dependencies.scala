import sbt._

object Dependencies {
  val logging: Seq[ModuleID] = Seq(
    "ch.qos.logback" % "logback-classic" % Versions.logback,
    "ch.qos.logback" % "logback-core" % Versions.logback,
    "org.slf4j" % "slf4j-api" % "2.0.12",
    "org.typelevel" %% "log4cats-slf4j" % "2.6.0"
  )

  val cats = Seq(
    "org.typelevel" %% "cats-core" % Versions.cats,
    "org.typelevel" %% "cats-effect" % Versions.catsEffect
  )

  val scalaCache = Seq(
    "com.github.cb372" %% "scalacache-caffeine" % "1.0.0-M6"
  )

  val fs2 = Seq(
    "co.fs2" %% "fs2-core" % Versions.fs2,
    "co.fs2" %% "fs2-io" % Versions.fs2
  )

  val bouncycastle = Seq(
    "org.bouncycastle" % "bcprov-jdk18on" % "1.78.1"
  )

  val scodec = Seq(
    "org.scodec" %% "scodec-core" % "2.2.2"
  )

  val levelDbJni = Seq(
    "com.halibobor" % "leveldbjni-all" % "1.23.2"
  )

  val caseApp = Seq(
    "com.github.alexarchambault" %% "case-app" % "2.1.0-M26"
  )

  val mUnitTest = Seq(
    "org.scalameta" %% "munit" % "1.0.0",
    "org.scalameta" %% "munit-scalacheck" % "1.0.0",
    "org.typelevel" %% "munit-cats-effect" % "2.0.0",
    "org.typelevel" %% "scalacheck-effect-munit" % "2.0-9366e44"
  ).map(_ % Test)
}

object Versions {
  val cats = "2.12.0"
  val catsEffect = "3.5.2"
  val fs2 = "3.10.2"
  val logback = "1.5.6"
}
