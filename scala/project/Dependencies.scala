import sbt.*

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

  val grpcServices = Seq(
    "io.grpc" % "grpc-services" % Versions.ioGrpc
  )

  val http4s = Seq(
    "org.http4s" %% "http4s-ember-client" % Versions.http4s,
    "org.http4s" %% "http4s-ember-server" % Versions.http4s,
    "org.http4s" %% "http4s-dsl" % Versions.http4s,
    "org.http4s" %% "http4s-circe" % Versions.http4s
  )

  val circe = Seq(
    "io.circe" %% "circe-core" % Versions.circe,
    "io.circe" %% "circe-generic" % Versions.circe,
    "io.circe" %% "circe-parser" % Versions.circe,
    "io.github.scalapb-json" %% "scalapb-circe" % "0.16.0"
  )

  val caseApp = Seq(
    "com.github.alexarchambault" %% "case-app" % "2.1.0-M28"
  )

  val sqlite = Seq(
    "org.xerial" % "sqlite-jdbc" % "3.46.0.0"
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
  val catsEffect = "3.5.4"
  val fs2 = "3.10.2"
  val circe = "0.14.9"
  val logback = "1.5.6"
  val ioGrpc = "1.65.1"
  val http4s = "0.23.27"
}
