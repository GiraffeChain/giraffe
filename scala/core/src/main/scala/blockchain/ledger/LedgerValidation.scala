package blockchain.ledger

import blockchain.ValidationResult
import blockchain.models.{Block, BlockBody, BlockId, Transaction}

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
