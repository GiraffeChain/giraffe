package blockchain.ledger

import blockchain.{FetchTransaction, ValidationResult}
import blockchain.models.*
import blockchain.codecs.given
import cats.data.{EitherT, NonEmptyChain}
import cats.effect.Sync
import cats.implicits.*

trait TransactionValidation[F[_]] {
  def validate(
      transaction: Transaction,
      context: TransactionValidationContext
  ): ValidationResult[F]
}

trait BodyValidation[F[_]] {
  def validate(
      body: BlockBody,
      context: TransactionValidationContext
  ): ValidationResult[F]
}

trait HeaderToBodyValidation[F[_]] {
  def validate(block: Block): ValidationResult[F]
}

case class TransactionValidationContext(
    parentBlockId: BlockId,
    height: Long,
    slot: Long
)

class TransactionValidationImpl[F[_]: Sync](
    fetchTransaction: FetchTransaction[F],
    transactionOutputState: TransactionOutputState[F],
    accountState: AccountState[F]
) extends TransactionValidation[F]:
  // TODO: Attestation validation

  override def validate(
      transaction: Transaction,
      context: TransactionValidationContext
  ): ValidationResult[F] =
    EitherT.fromEither[F](syntaxValidation(transaction)) >>
      dataCheck(transaction) >>
      spendableUtxoCheck(context.parentBlockId, transaction)

  private def syntaxValidation(
      transaction: Transaction
  ): Either[NonEmptyChain[String], Unit] =
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

  private def witnessTypeValidation(
      witness: Witness
  ): Either[NonEmptyChain[String], Unit] =
    (witness.lock.value, witness.key.value) match {
      case (_: Lock.Value.Ed25519, _: Key.Value.Ed25519) => ().asRight
      case _ => NonEmptyChain("InvalidKeyType").asLeft
    }

  private def dataCheck(transaction: Transaction): ValidationResult[F] =
    transaction.inputs
      .traverse(input =>
        EitherT(
          fetchTransaction(input.reference.transactionId)
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
      .void

  private def spendableUtxoCheck(
      parentBlockId: BlockId,
      transaction: Transaction
  ): ValidationResult[F] =
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

class BodyValidationImpl[F[_]: Sync](
    fetchTransaction: FetchTransaction[F],
    transactionValidation: TransactionValidation[F]
) extends BodyValidation[F]:
  override def validate(
      body: BlockBody,
      context: TransactionValidationContext
  ): ValidationResult[F] =
    body.transactionIds
      .foldLeftM(Set.empty[TransactionOutputReference])(
        (spentUtxos, transactionId) =>
          EitherT.liftF(fetchTransaction(transactionId)).flatMap {
            transaction =>
              val dependencies = transaction.dependencies
              EitherT.cond[F](
                spentUtxos.intersect(dependencies).isEmpty,
                (),
                NonEmptyChain("UnspendableUtxoReference")
              ) >>
                transactionValidation
                  .validate(transaction, context)
                  .as(spentUtxos ++ transaction.inputs.map(_.reference))
          }
      )
      .void
