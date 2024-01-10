package blockchain

import com.google.protobuf.ByteString

package object consensus:
  type Eta = ByteString
  type Rho = ByteString

  case class VrfArgument(eta: Eta, slot: Long)
