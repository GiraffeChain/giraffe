val scala3 = "3.4.2"

inThisBuild(
  List(
    organization := "com.giraffechain",
    scalaVersion := scala3,
    testFrameworks += TestFrameworks.MUnit,
    dockerRepository := Some("docker.io"),
    versionScheme := Some("early-semver"),
    dynverSeparator := "-",
    version := dynverGitDescribeOutput.value.mkVersion(versionFmt, fallbackVersion(dynverCurrentDate.value)),
    dynver := {
      val d = new java.util.Date
      sbtdynver.DynVer.getGitDescribeOutput(d).mkVersion(versionFmt, fallbackVersion(d))
    },
    semanticdbEnabled := true,
    semanticdbVersion := scalafixSemanticdb.revision
  )
)

lazy val blockchain = project
  .in(file("."))
  .settings(
    name := "giraffe",
    publish / skip := true,
    publishArtifact := false,
    scalaVersion := scala3
  )
  .aggregate(node, protobuf)

lazy val node = project
  .in(file("node"))
  .enablePlugins(DockerPlugin, JavaAppPackaging)
  .settings(
    dockerBaseImage := "eclipse-temurin:17-jre",
    dockerUpdateLatest := sys.env.get("DOCKER_PUBLISH_LATEST_TAG").fold(false)(_.toBoolean),
    dockerLabels ++= Map(
      "giraffe.version" -> version.value
    ),
    dockerExposedPorts := Seq(2023, 2024),
    Docker / packageName := "giraffe-node",
    dockerExposedVolumes += "/giraffe",
    dockerAlias := DockerAlias(Some("docker.io"), Some("seancheatham"), "giraffe-node", Some(version.value)),
    dockerAliases ++= (if (sys.env.get("DOCKER_PUBLISH_DEV_TAG").fold(false)(_.toBoolean))
                         Seq(dockerAlias.value.withTag(Some("dev")))
                       else Seq())
  )
  .settings(
    name := "giraffe-node",
    libraryDependencies ++=
      Dependencies.logging ++
        Dependencies.cats ++
        Dependencies.scalaCache ++
        Dependencies.bouncycastle ++
        Dependencies.scodec ++
        Dependencies.levelDbJni ++
        Dependencies.fs2 ++
        Dependencies.caseApp ++
        Dependencies.http4s ++
        Dependencies.mUnitTest ++
        Dependencies.circe ++
        Dependencies.sqlite,
    scalacOptions ++= Seq(
      "-source:3.4-migration",
      "-rewrite",
      "-Wunused:all"
    )
  )
  .dependsOn(protobuf)

lazy val copyProtobufTask =
  TaskKey[Unit]("copyProtobufTask", "Copy protobuf files from repository root")

lazy val protobuf =
  project
    .in(file("protobuf"))
    .enablePlugins(BuildInfoPlugin, Fs2Grpc)
    .settings(
      name := "giraffe-protobuf",
      buildInfoKeys := Seq[BuildInfoKey](
        name,
        version,
        scalaVersion,
        sbtVersion
      ),
      buildInfoPackage := "giraffe.protobuf",
      publish / skip := true,
      libraryDependencies ++= Seq(
        "com.thesamet.scalapb" %% "scalapb-runtime" % scalapb.compiler.Version.scalapbVersion % "protobuf",
        "com.thesamet.scalapb" %% "scalapb-validate-core" % scalapb.validate.compiler.BuildInfo.version % "protobuf"
      ),
      // This task copies all .proto files from the repository root into a directory that can be referenced by ScalaPB
      copyProtobufTask := {
        import java.nio.file.*
        import scala.jdk.CollectionConverters.*
        // Now, assemble a list of all of the .proto files in the repository root
        val protosRoot =
          Paths.get(Paths.get("").toAbsolutePath.getParent.toString, "proto")
        // The files will be copied into protobuf-fs2/target/protobuf-tmp
        val destinationBase =
          Paths.get((Compile / target).value.toString, "protobuf-tmp")
        if (
          Files.exists(protosRoot) && Files.exists(destinationBase) && compareProtoContents(protosRoot, destinationBase)
        ) {
          sLog.value.info("Proto contents up-to-date.  Skipping copying.")
        } else {
          // First, delete the existing tmp directory
          sLog.value.debug(s"Clearing protobuf-tmp directory=$destinationBase")
          if (Files.exists(destinationBase)) {
            Files
              .walk(destinationBase)
              .sorted(java.util.Comparator.reverseOrder[Path]())
              .iterator()
              .asScala
              .foreach(Files.delete)
          }
          val allFiles =
            Files
              .walk(protosRoot)
              .iterator()
              .asScala
              .map(_.toAbsolutePath)
              .toList
          val protoFiles =
            allFiles.filter(_.toString.endsWith(".proto"))
          // Copy each of the .proto files into the tmp directory
          sLog.value.info(
            s"Copying ${protoFiles.length} protobuf files to target/protobuf-tmp directory"
          )
          Files.createDirectories(destinationBase)
          Files.write(Paths.get(destinationBase.toString, "proto-contents.md5"), directoryMd5(protosRoot))
          protoFiles
            .foreach { protoFile =>
              // Preserve the directory structure when copying
              val destination = Paths.get(
                destinationBase.toString,
                protoFile.toString.drop(protosRoot.toString.length + 1)
              )
              sLog.value.debug(s"Copying from $protoFile to $destination")
              Files.createDirectories(destination.getParent)
              val contents = new String(Files.readAllBytes(protoFile), "UTF-8")
              val modifiedContents = modifyProtoContents(contents)
              Files.write(destination, modifiedContents.getBytes("UTF-8"))
            }
        }
      },
      (Compile / compile) := (Compile / compile)
        .dependsOn(copyProtobufTask)
        .value,
      (Compile / buildInfo) := (Compile / buildInfo)
        .dependsOn(Compile / PB.generate)
        .value,
      // Consume the copied files from the task above
      Compile / PB.protoSources := Seq(
        new java.io.File(s"${(Compile / target).value.toString}/protobuf-tmp")
      ),
      // By default, "managed sources" (the generated protobuf scala files) do not publish their source code,
      // so this step includes generated sources in the published package
      Compile / packageSrc / mappings ++= {
        val base = (Compile / sourceManaged).value
        val files = (Compile / managedSources).value
        files.map { f => (f, f.relativeTo(base).get.getPath) }
      },
      scalapbCodeGeneratorOptions ++= Seq(
        CodeGeneratorOption.FlatPackage,
        CodeGeneratorOption.Scala3Sources
      ),
      Compile / PB.targets := scalapbCodeGenerators.value
        .map(_.copy(outputPath = (Compile / sourceManaged).value))
        .:+(
          scalapb.validate.gen(
            scalapb.GeneratorOption.FlatPackage,
            scalapb.GeneratorOption.Scala3Sources
          ) -> (Compile / sourceManaged).value: protocbridge.Target
        )
    )

/** Instead of embedding scala-specific overrides in the protobuf files, we copy+modify the contents to embed any
  * Scala-specific code.
  * @param contents
  *   The contents of the original protobuf file
  * @return
  *   Updated contents, with scalapb validation included
  */
def modifyProtoContents(contents: String): String = {
  val syntaxStr = "syntax = \"proto3\";"
  val index = contents.indexOf(syntaxStr)
  require(index >= 0, s"Could not find $syntaxStr in protobuf file")
  s"""${contents.substring(0, index)}$syntaxStr
     |import "scalapb/scalapb.proto";
     |import "scalapb/validate.proto";
     |${if (!contents.contains("validate/validate.proto"))
      "import \"validate/validate.proto\";"
    else ""}
     |${contents.substring(index + syntaxStr.length)}
     |option (scalapb.options) = {
     |  [scalapb.validate.file] {
     |    validate_at_construction: true
     |  }
     |  field_transformations: [
     |    {
     |      when: {options: {[validate.rules] {message: {required: true}}}}
     |      set: {
     |        [scalapb.field] {
     |          required: true
     |        }
     |      }
     |    }
     |  ]
     |};
     |""".stripMargin
}

def directoryMd5(a: java.nio.file.Path): Array[Byte] = {
  import java.nio.file.*
  import java.security.*
  import scala.jdk.CollectionConverters.*
  val md = MessageDigest.getInstance("MD5")
  md.reset()
  Files
    .walk(a)
    .iterator()
    .asScala
    .filter(_.toString.endsWith(".proto"))
    .toList
    .sortBy(_.toString)
    .map(Files.readAllBytes)
    .foreach(md.update)
  md.digest()
}

def compareProtoContents(a: java.nio.file.Path, b: java.nio.file.Path): Boolean = {
  import java.nio.file.*
  val protoContentsFile = Paths.get(b.toString, "proto-contents.md5")
  if (Files.exists(protoContentsFile)) {
    val aDigest = directoryMd5(a)
    val bDigest = Files.readAllBytes(protoContentsFile)
    java.util.Arrays.equals(aDigest, bDigest)
  } else {
    false
  }
}

def versionFmt(out: sbtdynver.GitDescribeOutput): String = {
  val dirtySuffix = out.dirtySuffix.dropPlus.mkString("-", "")
  if (out.isCleanAfterTag) out.ref.dropPrefix + dirtySuffix // no commit info if clean after tag
  else out.ref.dropPrefix + out.commitSuffix.mkString("-", "-", "") + dirtySuffix
}

def fallbackVersion(d: java.util.Date): String = s"HEAD-${sbtdynver.DynVer.timestamp(d)}"

addCommandAlias("checkPR", s"; scalafixAll --check; scalafmtCheckAll; +test")
addCommandAlias("preparePR", s"; scalafixAll; scalafmtAll; +test")
addCommandAlias("checkPRTestQuick", s"; scalafixAll --check; scalafmtCheckAll; testQuick")
