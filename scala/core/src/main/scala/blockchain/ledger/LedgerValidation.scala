package blockchain.ledger

import blockchain.*
import blockchain.codecs.{*, given}
import blockchain.crypto.CryptoResources
import blockchain.models.*
import blockchain.utility.*
import cats.data.{EitherT, NonEmptyChain}
import cats.effect.{Resource, Sync}
import cats.implicits.*

trait TransactionValidation[F[_]]:
  def validate(transaction: Transaction, context: TransactionValidationContext): ValidationResult[F]

object TransactionValidation:
  def make[F[_]: Sync: CryptoResources](
      fetchTransaction: FetchTransaction[F],
      fetchTransactionOutput: FetchTransactionOutput[F],
      transactionOutputState: TransactionOutputState[F],
      accountState: AccountState[F],
      valueCalculator: ValueCalculator[F]
  ): Resource[F, TransactionValidation[F]] =
    Resource.pure(
      new TransactionValidationImpl[F](
        fetchTransaction,
        fetchTransactionOutput,
        transactionOutputState,
        accountState,
        valueCalculator
      )
    )

trait BodyValidation[F[_]]:
  def validate(body: FullBlockBody, context: TransactionValidationContext): ValidationResult[F]

object BodyValidation:
  def make[F[_]: Sync](transactionValidation: TransactionValidation[F]): Resource[F, BodyValidation[F]] =
    Resource.pure(new BodyValidationImpl[F](transactionValidation))

trait HeaderToBodyValidation[F[_]]:
  def validate(block: Block): ValidationResult[F]

object HeaderToBodyValidation:
  def make[F[_]: Sync](fetchHeader: FetchHeader[F]): Resource[F, HeaderToBodyValidation[F]] =
    Resource.pure((block: Block) =>
      EitherT(
        fetchHeader(block.header.parentHeaderId)
          .map(_.txRoot)
          .flatMap(parentTxRoot => Sync[F].delay(block.body.transactionIds.txRoot(parentTxRoot.decodeBase58)))
          .map(expectedTxRoot =>
            Either.cond(expectedTxRoot == block.header.txRoot.decodeBase58, (), NonEmptyChain("TxRoot Mismatch"))
          )
      )
    )

  def staticParentTxRoot[F[_]: Sync](txRoot: Bytes): Resource[F, HeaderToBodyValidation[F]] =
    Resource.pure((block: Block) =>
      EitherT(
        Sync[F]
          .delay(block.body.transactionIds.txRoot(txRoot))
          .map(expectedTxRoot =>
            Either.cond(expectedTxRoot == block.header.txRoot.decodeBase58, (), NonEmptyChain("TxRoot Mismatch"))
          )
      )
    )

case class TransactionValidationContext(
    parentBlockId: BlockId,
    height: Long,
    slot: Long
)

class TransactionValidationImpl[F[_]: Sync: CryptoResources](
    fetchTransaction: FetchTransaction[F],
    fetchTransactionOutput: FetchTransactionOutput[F],
    transactionOutputState: TransactionOutputState[F],
    accountState: AccountState[F],
    valueCalculator: ValueCalculator[F]
) extends TransactionValidation[F]:

  override def validate(transaction: Transaction, context: TransactionValidationContext): ValidationResult[F] =
    EitherT.fromEither[F](syntaxValidation(transaction)) >>
      valueCheck(transaction) >>
      attestationValidation(transaction) >>
      dataCheck(transaction) >>
      spendableUtxoCheck(context.parentBlockId, transaction)

  private def syntaxValidation(transaction: Transaction): Either[NonEmptyChain[String], Unit] =
    Either.cond(
      transaction.inputs.nonEmpty,
      (),
      NonEmptyChain("EmptyInputs")
    ) >>
      Either.cond(
        transaction.outputs.forall(_.value.quantity >= 0),
        (),
        NonEmptyChain("NonPositiveOutputQuantity")
      ) >>
      Either.cond(
        transaction.inputs.foldMap(_.value.quantity) >= transaction.outputs
          .foldMap(_.value.quantity),
        (),
        NonEmptyChain("InsufficientFunds")
      ) >>
      transaction.attestation.traverse(witnessTypeValidation).void

  private def valueCheck(transaction: Transaction): ValidationResult[F] =
    transaction.outputs
      .traverse(output =>
        EitherT(
          valueCalculator
            .requiredMinimumQuantity(output)
            .map(required =>
              Either.cond(
                output.value.quantity >= required,
                (),
                NonEmptyChain(s"InsufficientValue(${output.value.quantity} < $required)")
              )
            )
        )
      )
      .void

  private def witnessTypeValidation(witness: Witness): Either[NonEmptyChain[String], Unit] =
    (witness.lock.value, witness.key.value) match {
      case (_: Lock.Value.Ed25519, _: Key.Value.Ed25519) => ().asRight
      case _                                             => NonEmptyChain("InvalidKeyType").asLeft
    }

  private def dataCheck(transaction: Transaction): ValidationResult[F] =
    transaction.inputs
      .traverse(input =>
        EitherT
          .fromEither[F](input.reference.transactionId.toRight(NonEmptyChain("SelfSpend")))
          .flatMap(transactionId =>
            EitherT(
              fetchTransaction(transactionId)
                .map(_.outputs(input.reference.index))
                .map(output =>
                  Either.cond(
                    output.value.immutableBytes == input.value.immutableBytes,
                    (),
                    NonEmptyChain("InputOutputDataMismatch")
                  )
                )
            )
          )
      )
      .void

  private def spendableUtxoCheck(parentBlockId: BlockId, transaction: Transaction): ValidationResult[F] =
    transaction.dependencies.toList.traverse(dependency =>
      EitherT(
        transactionOutputState
          .transactionOutputIsSpendable(parentBlockId, dependency)
          .map(Either.cond(_, (), NonEmptyChain("UnspendableUtxoReference")))
      )
    ) >>
      transaction.inputs
        .filter(_.value.accountRegistration.nonEmpty)
        .traverse(input =>
          EitherT(
            accountState
              .accountUtxos(parentBlockId, input.reference)
              .map(utxos =>
                Either.cond(
                  utxos.exists(_.isEmpty),
                  (),
                  NonEmptyChain("NonEmptyAccount")
                )
              )
          )
        ) >>
      transaction.outputs
        .flatMap(_.account)
        .traverse(account =>
          EitherT(
            accountState
              .accountUtxos(parentBlockId, account)
              .map(utxos =>
                Either.cond(
                  utxos.nonEmpty,
                  (),
                  NonEmptyChain("NonExistentAccount")
                )
              )
          )
        )
        .void

  private def attestationValidation(transaction: Transaction): ValidationResult[F] =
    for {
      providedLockAddressesList <- EitherT.pure(transaction.attestation.map(_.lockAddress))
      providedLockAddresses = providedLockAddressesList.toSet
      _ <- EitherT.cond(
        providedLockAddressesList.length == providedLockAddresses.size,
        (),
        NonEmptyChain("Duplicate Witness")
      )
      requiredLockAddresses <- EitherT.liftF(transaction.requiredWitnesses(fetchTransactionOutput))
      _ <- EitherT.cond(requiredLockAddresses == providedLockAddresses, (), NonEmptyChain("Insufficient Witness"))
      signableBytes = transaction.signableBytes.toByteArray
      _ <- transaction.attestation.traverse(witnessValidation(signableBytes))
    } yield ()

  private def witnessValidation(signableBytes: Array[Byte])(witness: Witness): ValidationResult[F] =
    for {
      _ <- EitherT.cond[F](witness.lock.address == witness.lockAddress, (), NonEmptyChain("Lock-Address Mismatch"))
      _ <- (witness.lock.value, witness.key.value) match {
        case (l: Lock.Value.Ed25519, k: Key.Value.Ed25519) =>
          EitherT(
            CryptoResources[F].ed25519
              .useSync(e =>
                e.verify(k.value.signature.decodeBase58.toByteArray, signableBytes, l.value.vk.decodeBase58.toByteArray)
              )
              .map(Either.cond(_, (), NonEmptyChain("InvalidSignature")))
          )
        case _ => EitherT.leftT(NonEmptyChain("InvalidKeyType"))
      }
    } yield ()

class BodyValidationImpl[F[_]: Sync](transactionValidation: TransactionValidation[F]) extends BodyValidation[F]:
  override def validate(body: FullBlockBody, context: TransactionValidationContext): ValidationResult[F] =
    body.transactions
      .filter(_.rewardParentBlockId.isEmpty)
      .foldLeftM(Set.empty[TransactionOutputReference]) { (spentUtxos, transaction) =>
        val dependencies = transaction.dependencies
        EitherT.cond[F](
          spentUtxos.intersect(dependencies).isEmpty,
          (),
          NonEmptyChain("UnspendableUtxoReference")
        ) >>
          transactionValidation
            .validate(transaction, context)
            .as(spentUtxos ++ transaction.inputs.map(_.reference))
      } >> validateReward(body, context)

  private def validateReward(body: FullBlockBody, context: TransactionValidationContext) =
    EitherT(
      Sync[F]
        .delay(body.transactions.partition(_.rewardParentBlockId.isEmpty))
        .map((nonRewards, rewards) =>
          Either.cond(rewards.length <= 1, (nonRewards, rewards.headOption), NonEmptyChain("Duplicate Rewards"))
        )
    )
      .subflatMap((nonRewards, rewardOpt) =>
        rewardOpt
          .fold(().asRight[NonEmptyChain[String]])(reward =>
            Either.cond(
              reward.rewardParentBlockId.contains(context.parentBlockId),
              (),
              NonEmptyChain("RewardHeaderMismatch")
            ) >>
              Either.cond(reward.inputs.isEmpty, (), NonEmptyChain("RewardContainsInputs")) >>
              Either.cond(reward.outputs.length == 1, (), NonEmptyChain("RewardContainsMultipleOutputs")) >>
              Either.cond(
                reward.outputs.head.value.accountRegistration.isEmpty,
                (),
                NonEmptyChain("RewardContainsRegistration")
              ) >>
              Either.cond(
                reward.outputs.head.value.graphEntry.isEmpty,
                (),
                NonEmptyChain("RewardContainsGraphEntry")
              ) >>
              Either.cond(
                nonRewards.foldMap(_.reward) >= reward.outputs.head.value.quantity,
                (),
                NonEmptyChain("ExcessiveReward")
              )
          )
      )
      .void
