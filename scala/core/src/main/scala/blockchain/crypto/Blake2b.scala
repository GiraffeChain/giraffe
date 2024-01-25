package blockchain.crypto

import org.bouncycastle.crypto.digests.Blake2bDigest

abstract class Blake2b(lengthInBits: Int):
  private val digest = new Blake2bDigest(lengthInBits)
  private val lengthInBytes = lengthInBits / 8

  def hash(messages: Array[Byte]*): Array[Byte] =
    digest.reset()
    val out = new Array[Byte](lengthInBytes)
    messages.foreach(m => digest.update(m, 0, m.length))
    digest.doFinal(out, 0)
    out

class Blake2b256 extends Blake2b(256)
class Blake2b512 extends Blake2b(512)
