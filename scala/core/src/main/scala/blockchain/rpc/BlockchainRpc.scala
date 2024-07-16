package blockchain.rpc

import blockchain.codecs.given
import blockchain.BlockchainCore
import blockchain.consensus.TraversalStep
import blockchain.ledger.TransactionValidationContext
import blockchain.models.{BlockBody, FullBlockBody, SlotId}
import blockchain.services.*
import cats.MonadThrow
import cats.effect.Async
import cats.effect.kernel.Resource
import cats.implicits.*
import cats.effect.implicits.*
import io.grpc.{Metadata, Server}
import io.grpc.netty.shaded.io.grpc.netty.NettyServerBuilder
import io.grpc.protobuf.services.ProtoReflectionService

import java.net.InetSocketAddress
import fs2.Stream
import fs2.grpc.syntax.all.*
import org.typelevel.log4cats.Logger
import org.typelevel.log4cats.slf4j.Slf4jLogger
import scodec.bits.ByteVector

object BlockchainRpc:
  def serve[F[_]: Async](core: BlockchainCore[F], bindHost: String, bindPort: Int): Resource[F, Server] =
    Slf4jLogger
      .fromName("RPC")
      .toResource
      .flatTap(logger => Resource.onFinalize(logger.info("RPC Terminated")))
      .flatMap(logger =>
        List(
          NodeRpcFs2Grpc.bindServiceResource[F](new NodeServiceImpl(core)),
          StakerSupportRpcFs2Grpc.bindServiceResource[F](new StakerSupportImpl(core))
        ).sequence
          .flatMap(services =>
            services
              .foldLeft(NettyServerBuilder.forAddress(InetSocketAddress(bindHost, bindPort)))((builder, service) =>
                builder.addService(service)
              )
              .addService(ProtoReflectionService.newInstance())
              .resource[F]
          )
          .evalTap(server => Async[F].delay(server.start()))
          .evalTap(_ => logger.info(s"Serving RPC on bindHost=$bindHost bindPort=$bindPort"))
      )

class NodeServiceImpl[F[_]: Async](core: BlockchainCore[F]) extends NodeRpcFs2Grpc[F, Metadata]:
  private given logger: Logger[F] = Slf4jLogger.getLoggerFromName("RPC")
  override def broadcastTransaction(request: BroadcastTransactionReq, ctx: Metadata): F[BroadcastTransactionRes] =
    core.ledger.mempool.add(request.transaction).as(BroadcastTransactionRes()).warnLogErrors.adaptErrorsToGrpc

  override def getBlockHeader(request: GetBlockHeaderReq, ctx: Metadata): F[GetBlockHeaderRes] =
    core.dataStores.headers
      .get(request.blockId)
      .map(_.map(_.withEmbeddedId))
      .map(GetBlockHeaderRes(_))
      .warnLogErrors
      .adaptErrorsToGrpc

  override def getBlockBody(request: GetBlockBodyReq, ctx: Metadata): F[GetBlockBodyRes] =
    core.dataStores.bodies.get(request.blockId).map(GetBlockBodyRes(_)).warnLogErrors.adaptErrorsToGrpc

  override def getFullBlock(request: GetFullBlockReq, ctx: Metadata): F[GetFullBlockRes] =
    core.dataStores
      .fetchFullBlock(request.blockId)
      .map(_.map(b => b.update(_.header := b.header.withEmbeddedId)))
      .map(GetFullBlockRes(_))
      .warnLogErrors
      .adaptErrorsToGrpc

  override def getTransaction(request: GetTransactionReq, ctx: Metadata): F[GetTransactionRes] =
    core.dataStores.transactions
      .get(request.transactionId)
      .map(_.map(_.withEmbeddedId))
      .map(GetTransactionRes(_))
      .warnLogErrors
      .adaptErrorsToGrpc

  override def getBlockIdAtHeight(request: GetBlockIdAtHeightReq, ctx: Metadata): F[GetBlockIdAtHeightRes] =
    core.consensus.localChain
      .blockIdAtHeight(request.height)
      .map(GetBlockIdAtHeightRes(_))
      .warnLogErrors
      .adaptErrorsToGrpc

  override def follow(request: FollowReq, ctx: Metadata): Stream[F, FollowRes] =
    core.traversal.map {
      case TraversalStep.Applied(id)   => FollowRes().withAdopted(id)
      case TraversalStep.Unapplied(id) => FollowRes().withUnadopted(id)
    }.adaptErrorsToGrpc

class StakerSupportImpl[F[_]: Async](core: BlockchainCore[F]) extends StakerSupportRpcFs2Grpc[F, Metadata]:
  private given logger: Logger[F] = Slf4jLogger.getLoggerFromName("RPC")

  override def broadcastBlock(request: BroadcastBlockReq, ctx: Metadata): F[BroadcastBlockRes] = (
    for {
      header <- request.block.header.withEmbeddedId.pure[F]
      rewardTransaction = request.rewardTransaction.map(_.withEmbeddedId)
      rewardTransactionId = rewardTransaction.map(_.id)
      _ <- logger.info(show"Received block id=${header.id}")
      canonicalHeadId <- core.consensus.localChain.currentHead
      _ <- MonadThrow[F].raiseWhen(header.parentHeaderId != canonicalHeadId)(
        new IllegalArgumentException("Block does not extend local tip")
      )
      _ <- core.consensus.headerValidation
        .validate(header)
        .leftSemiflatTap(errors => logger.warn(show"Block id=${header.id} contains errors=$errors"))
        .leftMap(errors => new IllegalArgumentException(errors.head))
        .rethrowT
      _ <- core.blockIdTree.associate(header.id, header.parentHeaderId)
      _ <- core.dataStores.headers.put(header.id, header)
      _ <- core.dataStores.bodies.put(header.id, request.block.body)
      transactions <- request.block.body.transactionIds.traverse(id =>
        (rewardTransactionId.filter(_ == id) >> rewardTransaction)
          .fold(core.dataStores.transactions.getOrRaise(id))(_.pure[F])
      )
      _ <- core.ledger.bodyValidation
        .validate(
          FullBlockBody(transactions),
          TransactionValidationContext(header.parentHeaderId, header.height, header.slot)
        )
        .leftSemiflatTap(errors => logger.warn(show"Block id=${header.id} contains errors=$errors"))
        .leftMap(errors => new IllegalArgumentException(errors.head))
        .rethrowT
      _ <- MonadThrow[F].raiseWhen(header.parentHeaderId != canonicalHeadId)(
        new IllegalArgumentException("Block does not extend local tip")
      )
      _ <- core.consensus.localChain.adopt(header.id)
      _ <- logger.info(
        show"Adopted block id=${header.id} height=${header.height} slot=${header.slot} transactions=${request.block.body.transactionIds}"
      )
    } yield BroadcastBlockRes()
  ).warnLogErrors.adaptErrorsToGrpc

  override def getStaker(request: GetStakerReq, ctx: Metadata): F[GetStakerRes] =
    core.consensus.stakerTracker
      .staker(request.parentBlockId, request.slot, request.stakingAccount)
      .map(GetStakerRes(_))
      .warnLogErrors
      .adaptErrorsToGrpc

  override def getTotalActivestake(request: GetTotalActiveStakeReq, ctx: Metadata): F[GetTotalActiveStakeRes] =
    core.consensus.stakerTracker
      .totalActiveStake(request.parentBlockId, request.slot)
      .map(GetTotalActiveStakeRes(_))
      .warnLogErrors
      .adaptErrorsToGrpc

  override def calculateEta(request: CalculateEtaReq, ctx: Metadata): F[CalculateEtaRes] =
    core.dataStores.headers
      .getOrRaise(request.parentBlockId)
      .flatMap(header =>
        core.consensus.etaCalculation
          .etaToBe(SlotId(header.slot, header.id), request.slot)
          .map(eta => ByteVector(eta.toByteArray).toBase58)
          .map(CalculateEtaRes(_))
      )
      .warnLogErrors
      .adaptErrorsToGrpc

  override def packBlock(request: PackBlockReq, ctx: Metadata): Stream[F, PackBlockRes] =
    core.ledger.blockPacker.streamed
      .map(fullBody => PackBlockRes(BlockBody(fullBody.transactions.map(_.id))))
      .mergeHaltR(Stream.exec(core.clock.delayedUntilSlot(request.untilSlot)))
      .adaptErrorsToGrpc
