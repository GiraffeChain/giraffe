package com.giraffechain.codecs

import cats.effect.IO
import com.giraffechain.models.Transaction
import munit.CatsEffectSuite
import scodec.bits.ByteVector

class CodecsTest extends CatsEffectSuite:
  Specs.allSpecs.zipWithIndex.foreach((spec, index) =>
    test(s"Spec$index") {
      val tx = Transaction.parseFrom(ByteVector.fromValidHex(spec.txHex).toArray)
      IO(ByteVector(tx.signableBytes.toByteArray).toHex).assertEquals(spec.signableBytesHex)
    }
  )

case class Spec(txHex: String, signableBytesHex: String)

object Specs:
  val allSpecs: List[Spec] = List(
    Spec(
      "0a2e0a2c4766736e666362346270665678776b316365765651627274576a694673566434666546446d586768666e473312380a300a2e0a2c475652617068627859516d7933395731386566797462545a423643706b543951635842314e70693834516154120408d086031a320a2e0a2c474c7a677966356b6743724b7455414c47765234433733486a6234716575526b3663527352585853354c756d12001a360a2e0a2c45616f5a4855324658796f3572355344555457447239694c6f4c43546550396a786757463570547a5a776777120408e8fe02",
      "0000000101e6275ce07860f04ffee249822c2f05c3a5dc6b8ce964fb2c281a0b1371385c9800000000000000000000c350000000000002e3fe919773b6f4d90306d1af3c9907240dda6d36265667723d854ed89a96db100000000000000000000000c9d0bd0cf3098b102043992f33fc39fdf639735ea1dc665b8ffcc2d21efd9234000000000000bf6800000000"
    )
  )
