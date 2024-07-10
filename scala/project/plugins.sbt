Seq(
  "org.scalameta" % "sbt-scalafmt" % "2.5.2",
  "ch.epfl.scala" % "sbt-scalafix" % "0.11.1",
  "com.github.sbt" % "sbt-native-packager" % "1.9.16",
  "com.eed3si9n" % "sbt-buildinfo" % "0.11.0",
  "org.typelevel" % "sbt-fs2-grpc" % "2.7.11",
  "com.thesamet" % "sbt-protoc" % "1.0.6",
  "com.github.sbt" % "sbt-dynver" % "5.0.1"
).map(addSbtPlugin)

libraryDependencies ++= Seq(
  "com.thesamet.scalapb" %% "compilerplugin" % "0.11.14",
  "com.thesamet.scalapb" %% "scalapb-validate-codegen" % "0.3.4"
)
