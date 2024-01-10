package blockchain.consensus

import blockchain.ValidationResult
import blockchain.models.BlockHeader

trait HeaderValidation[F[_]]:
  def validate(blockHeader: BlockHeader): ValidationResult[F]
