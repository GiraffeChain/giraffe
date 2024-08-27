package blockchain.rpc

import blockchain.BlockchainCore
import blockchain.codecs.{*, given}
import blockchain.consensus.TraversalStep
import blockchain.ledger.WhereClause
import blockchain.models.*
import cats.data.OptionT
import cats.effect.implicits.*
import cats.effect.{IO, Resource}
import cats.implicits.*
import com.comcast.ip4s.{Host, Port}
import fs2.Stream
import io.circe.syntax.*
import io.circe.{Decoder, DecodingFailure, Encoder, Json}
import org.http4s.*
import org.http4s.circe.*
import org.http4s.circe.CirceEntityCodec.*
import org.http4s.dsl.io.*
import org.http4s.ember.server.EmberServerBuilder
import org.http4s.server.Router
import org.http4s.server.middleware.CORS
import org.typelevel.log4cats.slf4j.Slf4jLogger
import org.typelevel.log4cats.{Logger, LoggerFactory}
import scalapb_circe.codec.*
import scodec.bits.ByteVector

import scala.concurrent.duration.*

class JsonBlockchainRpc(core: BlockchainCore[IO])(using LoggerFactory[IO]) {
  type F[A] = IO[A]

  import JsonBlockchainRpc.{*, given}

  private given Logger[F] = Slf4jLogger.getLoggerFromName("ApiServer")

  def serve(bindHost: String, bindPort: Int): Resource[IO, Unit] =
    Resource
      .eval(
        IO
          .delay(
            (Host.fromString(bindHost), Port.fromInt(bindPort)).tupled
              .toRight(new IllegalArgumentException("Invalid bindHost/bindPort"))
          )
          .rethrow
      )
      .flatMap((host, port) =>
        EmberServerBuilder
          .default[IO]
          .withHost(host)
          .withPort(port)
          .withHttpApp(
            CORS.policy.withAllowOriginAll.withAllowMethodsAll
              .withAllowHeadersAll(
                Router("/api" -> apiRoutes, "/" -> webRoutes)
              )
              .orNotFound
          )
          .build
          .evalTap(_ => Logger[F].info(s"JSON RPC server started on $host:$port"))
      )
      .void

  private val webRoutes: HttpRoutes[IO] = {
    val classloader = this.getClass.getClassLoader
    HttpRoutes.of[IO] {
      case req @ GET -> Root =>
        StaticFile
          .fromResource[IO]("/web/index.html", req.some, classloader = classloader.some)
          .getOrElseF(NotFound("Well this is awkward..."))
      case req @ GET -> path =>
        StaticFile
          .fromResource[IO](s"/web/$path", req.some, classloader = classloader.some)
          .getOrElseF(NotFound("Well this is super awkward..."))
    }
  }

  private val apiRoutes: HttpRoutes[IO] =
    HttpRoutes.of[IO] {
      case GET -> Root =>
        Ok(Json.obj("hello" -> "world".asJson)).logError
      case GET -> Root / "block-headers" / id =>
        OptionT(IO(id.decodeBlockId).flatMap(core.dataStores.headers.get))
          .map(_.withEmbeddedId)
          .map(_.asJson)
          .fold(Response().withStatus(Status.NotFound))(Response().withEntity)
          .logError
      case GET -> Root / "block-bodies" / id =>
        OptionT(IO(id.decodeBlockId).flatMap(core.dataStores.bodies.get))
          .map(_.asJson)
          .fold(Response().withStatus(Status.NotFound))(Response().withEntity)
      case GET -> Root / "blocks" / id =>
        OptionT(IO(id.decodeBlockId).flatMap(core.dataStores.fetchFullBlock))
          .map(b => b.update(_.header := b.header.withEmbeddedId))
          .map(_.asJson)
          .fold(Response().withStatus(Status.NotFound))(Response().withEntity)
          .logError
      case GET -> Root / "transactions" / id =>
        OptionT(IO(id.decodeTransactionId).flatMap(core.dataStores.transactions.get))
          .map(_.withEmbeddedId)
          .map(_.asJson)
          .fold(Response().withStatus(Status.NotFound))(Response().withEntity)
          .logError
      case GET -> Root / "block-ids" / height =>
        OptionT(IO(height.toIntOption))
          .foldF(Response().withStatus(Status.BadRequest).pure[F])(h =>
            OptionT(core.consensus.localChain.blockIdAtHeight(h))
              .map(id => Json.obj("blockId" -> id.show.asJson))
              .fold(Response().withStatus(Status.NotFound))(Response().withEntity)
          )
          .logError
      case GET -> Root / "follow" =>
        IO(
          Response(
            body = core.traversal
              .map {
                case TraversalStep.Applied(id)   => Json.obj("adopted" -> id.show.asJson)
                case TraversalStep.Unapplied(id) => Json.obj("unadopted" -> id.show.asJson)
              }
              .map(_.noSpaces)
              .mergeHaltL(JsonBlockchainRpc.keepAliveTickStream)
              .intersperse("\n")
              .through(fs2.text.utf8.encode)
              .onError { case e =>
                Stream.exec(Logger[F].warn(e)("Follow failure"))
              }
          )
        )
      case GET -> Root / "account-states" / transactionId / index =>
        OptionT(IO(index.toIntOption))
          .foldF(Response().withStatus(Status.BadRequest).pure[F])(index =>
            IO(transactionId.decodeTransactionId)
              .map(TransactionOutputReference(_, index))
              .flatMap(account =>
                OptionT(
                  core.consensus.localChain.currentHead.flatMap(core.ledger.accountState.accountUtxos(_, account))
                )
                  .getOrElse(Nil)
              )
              .map(_.asJson)
              .map(Response().withEntity)
          )
          .logError
      case GET -> Root / "address-states" / address =>
        IO(address.decodeLockAddress)
          .flatMap(address =>
            OptionT(core.consensus.localChain.currentHead.flatMap(core.ledger.addressState.addressUtxos(_, address)))
              .getOrElse(Nil)
          )
          .map(_.asJson)
          .map(Response().withEntity)
          .logError
      case GET -> Root / "transaction-outputs" / transactionId / index =>
        OptionT(IO(index.toIntOption))
          .foldF(Response().withStatus(Status.BadRequest).pure[F])(index =>
            IO(transactionId.decodeTransactionId)
              .flatMap(transactionId =>
                OptionT(core.dataStores.transactions.get(transactionId))
                  .subflatMap(_.outputs.lift(index))
                  .map(_.asJson)
                  .fold(Response().withStatus(Status.NotFound))(Response().withEntity)
              )
          )
          .logError
      case GET -> Root / "graph" / transactionId / index / "edges" =>
        OptionT(IO(index.toIntOption))
          .foldF(Response().withStatus(Status.BadRequest).pure[F])(index =>
            IO(transactionId.decodeTransactionId)
              .map(TransactionOutputReference(_, index))
              .flatMap(reference =>
                core.consensus.localChain.currentHead
                  .flatMap(core.ledger.graphState.edges(_)(reference))
                  .map(_.asJson)
                  .map(Response().withEntity)
              )
          )
          .logError
      case request @ POST -> Root / "graph" / "query-vertices" =>
        request
          .as[VertexQuery]
          .flatMap(query =>
            core.consensus.localChain.currentHead
              .flatMap(core.ledger.graphState.queryVertices(_)(query.label, query.where))
              .map(_.asJson)
              .map(Response().withEntity)
          )
          .logError
      case request @ POST -> Root / "graph" / "query-edges" =>
        request
          .as[EdgeQuery]
          .flatMap(query =>
            core.consensus.localChain.currentHead
              .flatMap(core.ledger.graphState.queryEdges(_)(query.label, query.a, query.b, query.where))
              .map(_.asJson)
              .map(Response().withEntity)
          )
          .logError
      case GET -> Root / "graph" / transactionId / index / "in-edges" =>
        OptionT(IO(index.toIntOption))
          .foldF(Response().withStatus(Status.BadRequest).pure[F])(index =>
            IO(transactionId.decodeTransactionId)
              .map(TransactionOutputReference(_, index))
              .flatMap(reference =>
                core.consensus.localChain.currentHead
                  .flatMap(core.ledger.graphState.inEdges(_)(reference))
                  .map(_.asJson)
                  .map(Response().withEntity)
              )
          )
          .logError
      case GET -> Root / "graph" / transactionId / index / "out-edges" =>
        OptionT(IO(index.toIntOption))
          .foldF(Response().withStatus(Status.BadRequest).pure[F])(index =>
            IO(transactionId.decodeTransactionId)
              .map(TransactionOutputReference(_, index))
              .flatMap(reference =>
                core.consensus.localChain.currentHead
                  .flatMap(core.ledger.graphState.outEdges(_)(reference))
                  .map(_.asJson)
                  .map(Response().withEntity)
              )
          )
          .logError
      case request @ POST -> Root / "transactions" =>
        request
          .as[Json]
          .flatMap(json => IO.fromEither(json.as[Transaction]))
          .flatMap(core.ledger.mempool.add)
          .as(Response())
          .logError
      case request @ POST -> Root / "blocks" =>
        request
          .as[Json]
          .flatMap(json =>
            IO.fromEither(
              (json.hcursor.get[Block]("block"), json.hcursor.get[Option[Transaction]]("reward")).tupled
            )
          )
          .flatMap(broadcastBlockImpl(core))
          .as(Response())
          .logError
      case GET -> Root / "stakers" / parentBlockId / slot / accountTransactionId / accountTransactionIndex =>
        (
          IO(parentBlockId.decodeBlockId),
          IO.fromOption(slot.toLongOption)(new IllegalArgumentException("Invalid slot")),
          IO(accountTransactionId.decodeTransactionId),
          IO.fromOption(accountTransactionIndex.toIntOption)(
            new IllegalArgumentException("Invalid accountTransactionIndex")
          )
        ).tupled
          .flatMap((parentBlockId, slot, accountTransactionId, accountTransactionIndex) =>
            core.consensus.stakerTracker
              .staker(parentBlockId, slot, TransactionOutputReference(accountTransactionId, accountTransactionIndex))
          )
          .map(_.asJson)
          .map(Response().withEntity)
          .logError
      case GET -> Root / "total-active-stake" / parentBlockId / slot =>
        (
          IO(parentBlockId.decodeBlockId),
          IO.fromOption(slot.toLongOption)(new IllegalArgumentException("Invalid slot"))
        ).tupled
          .flatMap(core.consensus.stakerTracker.totalActiveStake.tupled)
          .map(total => Json.obj("totalActiveStake" -> total.asJson))
          .map(Response().withEntity)
          .logError
      case GET -> Root / "eta" / parentBlockId / slot =>
        (
          IO(parentBlockId.decodeBlockId),
          IO.fromOption(slot.toLongOption)(new IllegalArgumentException("Invalid slot"))
        ).tupled
          .flatMap((parentBlockId, slot) =>
            core.dataStores.headers
              .getOrRaise(parentBlockId)
              .flatMap(header =>
                core.consensus.etaCalculation
                  .etaToBe(SlotId(header.slot, header.id), slot)
                  .map(eta => ByteVector(eta.toByteArray).toBase58)
              )
          )
          .map(eta => Json.obj("eta" -> eta.asJson))
          .map(Response().withEntity)
          .logError
      case GET -> Root / "block-packer" =>
        IO(
          Response(body =
            core.ledger.blockPacker.streamed
              .map(full => BlockBody(full.transactions.map(_.id)))
              .map(_.asJson.noSpaces)
              .mergeHaltL(JsonBlockchainRpc.keepAliveTickStream)
              .intersperse("\n")
              .through(fs2.text.utf8.encode)
              .onError { case e =>
                Stream.exec(Logger[F].warn(e)("Block packer failure"))
              }
          )
        )
    }

}

object JsonBlockchainRpc:
  val keepAliveTickStream: Stream[IO, String] = Stream.fixedRate[IO](500.milli).as("")

  case class VertexQuery(label: String, where: Seq[WhereClause])
  case class EdgeQuery(label: String, a: Option[String], b: Option[String], where: Seq[WhereClause])

  given Decoder[WhereClause] = c =>
    c.as[List[Json]].flatMap {
      case List(key, operand, value) =>
        for {
          keyStr <- key.as[String]
          operandStr <- operand.as[String]
          operand <- operandStr match {
            case "==" => WhereClause.OperandEq.asRight
            case _    => DecodingFailure(s"Invalid operand: $operandStr", c.history).asLeft
          }
        } yield WhereClause(keyStr, operand, value)
      case _ => DecodingFailure("Invalid where clause", c.history).asLeft
    }

  given Decoder[VertexQuery] = c =>
    for {
      label <- c.downField("label").as[String]
      where <- c.getOrElse[Seq[WhereClause]]("where")(Nil)
    } yield VertexQuery(label, where)

  given Decoder[EdgeQuery] = c =>
    for {
      label <- c.downField("label").as[String]
      a <- c.downField("a").as[Option[String]]
      b <- c.downField("b").as[Option[String]]
      where <- c.getOrElse[Seq[WhereClause]]("where")(Nil)
    } yield EdgeQuery(label, a, b, where)
