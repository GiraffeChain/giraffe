package blockchain.rpc

import blockchain.codecs.given
import blockchain.BlockchainCore
import blockchain.consensus.TraversalStep
import blockchain.ledger.TransactionValidationContext
import blockchain.models.{BlockBody, SlotId}
import blockchain.services.*
import cats.MonadThrow
import cats.effect.Async
import cats.implicits.*
import io.grpc.Metadata

class BlockchainRpc {}

class NodeServiceImpl[F[_]: Async](core: BlockchainCore[F])
    extends NodeRpcFs2Grpc[F, Metadata]:
  override def broadcastTransaction(
      request: BroadcastTransactionReq,
      ctx: Metadata
  ): F[BroadcastTransactionRes] =
    core.ledger.mempool.add(request.transaction).as(BroadcastTransactionRes())

  override def getBlockHeader(
      request: GetBlockHeaderReq,
      ctx: Metadata
  ): F[GetBlockHeaderRes] =
    core.dataStores.headers.get(request.blockId).map(GetBlockHeaderRes(_))

  override def getBlockBody(
      request: GetBlockBodyReq,
      ctx: Metadata
  ): F[GetBlockBodyRes] =
    core.dataStores.bodies.get(request.blockId).map(GetBlockBodyRes(_))

  override def getFullBlock(
      request: GetFullBlockReq,
      ctx: Metadata
  ): F[GetFullBlockRes] =
    core.dataStores.fetchFullBlock(request.blockId).map(GetFullBlockRes(_))

  override def getTransaction(
      request: GetTransactionReq,
      ctx: Metadata
  ): F[GetTransactionRes] =
    core.dataStores.transactions
      .get(request.transactionId)
      .map(GetTransactionRes(_))

  override def getBlockIdAtHeight(
      request: GetBlockIdAtHeightReq,
      ctx: Metadata
  ): F[GetBlockIdAtHeightRes] =
    core.consensus.localChain
      .blockIdAtHeight(request.height)
      .map(GetBlockIdAtHeightRes(_))

  override def follow(
      request: FollowReq,
      ctx: Metadata
  ): fs2.Stream[F, FollowRes] =
    core.traversal.map {
      case TraversalStep.Applied(id)   => FollowRes().withAdopted(id)
      case TraversalStep.Unapplied(id) => FollowRes().withUnadopted(id)
    }

class StakerSupportImpl[F[_]: Async](core: BlockchainCore[F])
    extends StakerSupportRpcFs2Grpc[F, Metadata]:
  override def broadcastBlock(
      request: BroadcastBlockReq,
      ctx: Metadata
  ): F[BroadcastBlockRes] =
    for {
      header <- request.block.header.withEmbeddedId.pure[F]
      canonicalHeadId <- core.consensus.localChain.currentHead
      _ <- core.consensus.headerValidation
        .validate(header)
        .leftMap(errors => new IllegalArgumentException(errors.head))
        .rethrowT
      _ <- core.blockIdTree.associate(header.id, header.parentHeaderId)
      _ <- core.dataStores.headers.put(header.id, header)
      _ <- core.dataStores.bodies.put(header.id, request.block.body)
      _ <- core.ledger.bodyValidation
        .validate(
          request.block.body,
          TransactionValidationContext(header.id, header.height, header.slot)
        )
        .leftMap(errors => new IllegalArgumentException(errors.head))
        .rethrowT
      _ <- MonadThrow[F].raiseWhen(header.parentHeaderId != canonicalHeadId)(
        new IllegalArgumentException("Block does not extend local tip")
      )
      _ <- core.consensus.localChain.adopt(header.id)
    } yield BroadcastBlockRes()

  override def getStaker(
      request: GetStakerReq,
      ctx: Metadata
  ): F[GetStakerRes] =
    core.consensus.stakerTracker
      .staker(request.parentBlockId, request.slot, request.stakingAccount)
      .map(GetStakerRes(_))

  override def getTotalActivestake(
      request: GetTotalActiveStakeReq,
      ctx: Metadata
  ): F[GetTotalActiveStakeRes] =
    core.consensus.stakerTracker
      .totalActiveStake(request.parentBlockId, request.slot)
      .map(GetTotalActiveStakeRes(_))

  override def calculateEta(
      request: CalculateEtaReq,
      ctx: Metadata
  ): F[CalculateEtaRes] =
    core.dataStores.headers
      .getOrRaise(request.parentBlockId)
      .flatMap(header =>
        core.consensus.etaCalculation
          .etaToBe(SlotId(header.slot, header.id), request.slot)
          .map(CalculateEtaRes(_))
      )

  override def packBlock(
      request: PackBlockReq,
      ctx: Metadata
  ): fs2.Stream[F, PackBlockRes] =
    core.ledger.blockPacker.streamed
      .map(fullBody => PackBlockRes(BlockBody(fullBody.transactions.map(_.id))))
      .mergeHaltR(
        fs2.Stream.exec(core.clock.delayedUntilSlot(request.untilSlot))
      )
