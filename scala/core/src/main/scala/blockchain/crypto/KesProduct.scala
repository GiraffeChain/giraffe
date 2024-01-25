package blockchain.crypto

import blockchain.crypto.KesBinaryTree.*
import com.google.common.primitives.Longs

import java.security.SecureRandom
import scala.collection.mutable

class KesProduct extends ProductComposition {

  def createKeyPair(
      seed: Array[Byte],
      height: (Int, Int),
      offset: Long
  ): (SecretKeyKesProduct, VerificationKeyKesProduct) = {
    val sk = generateSecretKey(seed, height._1, height._2)
    val pk = generateVerificationKey(sk)
    (
      SecretKeyKesProduct(
        sk._1,
        sk._2,
        sk._3,
        SignatureKesSum(
          sk._4._1,
          sk._4._2,
          sk._4._3
        ),
        offset
      ),
      VerificationKeyKesProduct(pk._1, pk._2)
    )
  }

  def sign(
      privateKey: SecretKeyKesProduct,
      message: Array[Byte]
  ): SignatureKesProduct = {
    val prodSig = sign(unpackSecret(privateKey), message)

    SignatureKesProduct(
      SignatureKesSum(
        prodSig._1._1,
        prodSig._1._2,
        prodSig._1._3
      ),
      SignatureKesSum(
        prodSig._2._1,
        prodSig._2._2,
        prodSig._2._3
      ),
      prodSig._3
    )
  }

  def verify(
      signature: SignatureKesProduct,
      message: Array[Byte],
      verifyKey: VerificationKeyKesProduct
  ): Boolean = {
    val prodSig = (
      (
        signature.superSignature.verificationKey,
        signature.superSignature.signature,
        signature.superSignature.witness.toVector
      ),
      (
        signature.subSignature.verificationKey,
        signature.subSignature.signature,
        signature.subSignature.witness.toVector
      ),
      signature.subRoot
    )

    val sumVk = (verifyKey.value, verifyKey.step)
    verify(prodSig, message.toArray, sumVk)
  }

  def update(
      privateKey: SecretKeyKesProduct,
      steps: Int
  ): SecretKeyKesProduct = {
    val sk = updateKey(unpackSecret(privateKey), steps)

    SecretKeyKesProduct(
      sk._1,
      sk._2,
      sk._3,
      SignatureKesSum(
        sk._4._1,
        sk._4._2,
        sk._4._3
      ),
      privateKey.offset
    )
  }

  def getCurrentStep(privateKey: SecretKeyKesProduct): Int = getKeyTime(
    unpackSecret(privateKey)
  )

  def getMaxStep(privateKey: SecretKeyKesProduct): Int = exp(
    getTreeHeight(privateKey.superTree) + getTreeHeight(privateKey.subTree)
  )

  def getVerificationKey(
      privateKey: SecretKeyKesProduct
  ): VerificationKeyKesProduct = {
    val vk = generateVerificationKey(unpackSecret(privateKey))
    VerificationKeyKesProduct(vk._1, vk._2)
  }

  private def unpackSecret(privateKey: SecretKeyKesProduct): SK =
    (
      privateKey.superTree,
      privateKey.subTree,
      privateKey.nextSubSeed,
      (
        privateKey.subSignature.verificationKey,
        privateKey.subSignature.signature,
        privateKey.subSignature.witness.toVector
      )
    )

}

case class SecretKeyKesProduct(
    superTree: KesBinaryTree, // Hour hand
    subTree: KesBinaryTree, // Minute hand
    nextSubSeed: Array[Byte],
    subSignature: SignatureKesSum,
    offset: Long
) {

  override def equals(obj: Any): Boolean =
    obj.asInstanceOf[Matchable] match {
      case s: SecretKeyKesProduct =>
        superTree == s.superTree &&
        subTree == s.subTree &&
        java.util.Arrays.equals(nextSubSeed, s.nextSubSeed) &&
        subSignature == s.subSignature &&
        offset == s.offset
      case _ =>
        false
    }

  override def hashCode(): Int = {
    var r = 1

    r = 31 * r + superTree.hashCode()
    r = 31 * r + subTree.hashCode()
    r = 31 * r + java.util.Arrays.hashCode(nextSubSeed)
    r = 31 * r + subSignature.hashCode()
    r = 31 * r + offset.hashCode()
    r
  }

  def toByteArray: Array[Byte] =
    mutable.ArrayBuilder
      .make[Byte]
      .addAll(superTree.toByteArray)
      .addAll(subTree.toByteArray)
      .addAll(nextSubSeed)
      .addAll(subSignature.toByteArray)
      .addAll(Longs.toByteArray(offset))
      .result()
}

case class SignatureKesProduct(
    superSignature: SignatureKesSum,
    subSignature: SignatureKesSum,
    subRoot: Array[Byte]
) {

  override def hashCode(): Int = {
    var r = 1
    r = 31 * r + superSignature.hashCode()
    r = 31 * r + subSignature.hashCode()
    r = 31 * r + java.util.Arrays.hashCode(subRoot)
    r
  }

  override def equals(other: Any): Boolean =
    other.asInstanceOf[Matchable] match {
      case kesProduct: SignatureKesProduct =>
        superSignature == kesProduct.superSignature &&
        subSignature == kesProduct.subSignature &&
        subRoot.sameElements(kesProduct.subRoot)

      case _ => false
    }
}

case class VerificationKeyKesProduct(value: Array[Byte], step: Int) {

  override def hashCode(): Int = {
    var r = 1
    r = 31 * r + java.util.Arrays.hashCode(value)
    r = 31 * r + step.hashCode
    r
  }

  override def equals(other: Any): Boolean =
    other.asInstanceOf[Matchable] match {
      case vk: VerificationKeyKesProduct =>
        value.sameElements(vk.value) &&
        step == vk.step
      case _ => false
    }
}

/** Credit to Aaron Schutza
  */
private[crypto] class ProductComposition extends KesEd25519Blake2b256 {

  protected val sumComposition = new SumComposition

  protected val random: SecureRandom = new SecureRandom

  override type SIG = (sumComposition.SIG, sumComposition.SIG, Array[Byte])
  override type VK = (Array[Byte], Int)
  override type SK =
    (sumComposition.SK, sumComposition.SK, Array[Byte], sumComposition.SIG)

  /** Get the current time step of an MMM key
    * @param key
    *   MMM key to be inspected
    * @return
    *   Current time step of key
    */
  private[crypto] def getKeyTime(key: SK): Int = {
    val numSubSteps = exp(sumComposition.getTreeHeight(key._2))
    val tSup = sumComposition.getKeyTime(key._1)
    val tSub = sumComposition.getKeyTime(key._2)
    (tSup * numSubSteps) + tSub
  }

  /** @param key
    * @return
    */
  private[crypto] def generateVerificationKey(key: SK): VK = key._1 match {
    case node: MerkleNode  => (witness(node), getKeyTime(key))
    case leaf: SigningLeaf => (witness(leaf), 0)
    case Empty()           => (Array.fill(hashBytes)(0: Byte), 0)
  }

  /** Generate key in the MMM composition
    * @param seed
    *   input entropy for key generation
    * @return
    */
  private[crypto] def generateSecretKey(
      seed: Array[Byte],
      heightSup: Int,
      heightSub: Int
  ): SK = {
    val rSuper = prng(seed)
    val rSub = prng(rSuper._2)
    val superScheme = sumComposition.generateSecretKey(rSuper._1, heightSup)
    val subScheme = sumComposition.generateSecretKey(rSub._1, heightSub)
    val kesVkSub: sumComposition.VK =
      sumComposition.generateVerificationKey(subScheme)
    val kesSigSup: sumComposition.SIG =
      sumComposition.sign(superScheme, kesVkSub._1)
    random.nextBytes(rSuper._2)
    random.nextBytes(seed)
    (superScheme, subScheme, rSub._2, kesSigSup)
  }

  /** Erases the secret key at the leaf level of a private key in the sum composition Used to commit to a child
    * verification key and then convert the parent private key to a state that can't be used to re-commit to another
    * child key until the next time step
    * @param input
    *   input key
    * @return
    *   new key with overwritten SigningLeaf sk
    */

  private[crypto] def eraseLeafSecretKey(input: KesBinaryTree): KesBinaryTree =
    input match {
      case n: MerkleNode =>
        (n.left, n.right) match {
          case (Empty(), _) =>
            MerkleNode(
              n.seed,
              n.witnessLeft,
              n.witnessRight,
              Empty(),
              eraseLeafSecretKey(n.right)
            )
          case (_, Empty()) =>
            MerkleNode(
              n.seed,
              n.witnessLeft,
              n.witnessRight,
              eraseLeafSecretKey(n.left),
              Empty()
            )
          case (_, _) => throw new Exception("Evolving Key Configuration Error")
        }
      case l: SigningLeaf =>
        random.nextBytes(l.sk)
        SigningLeaf(Array.fill[Byte](sig.SECRET_KEY_SIZE)(0), l.vk)
      case _ => throw new Exception("Evolving Key Configuration Error")
    }

  /** Erases the secret key at the leaf level of a private key in the product composition Used to commit to a child
    * verification key and then convert the parent private key to a state that can't be used to re-commit to another
    * child key until the next time step
    * @param key
    *   input key
    * @return
    *   new key with overwritten child scheme SigningLeaf sk
    */

  private[crypto] def eraseProductLeafSk(key: SK): SK =
    (key._1, eraseLeafSecretKey(key._2), key._3, key._4)

  /** Updates product keys to the specified time step
    * @param key
    *   input key
    * @param step
    *   input desired time step
    * @return
    *   updated key
    */
  private[crypto] def updateKey(key: SK, step: Int): SK = {
    val keyTime = getKeyTime(key)
    val keyTimeSup = sumComposition.getKeyTime(key._1)
    val heightSup = sumComposition.getTreeHeight(key._1)
    val heightSub = sumComposition.getTreeHeight(key._2)
    val totalSteps = exp(heightSup + heightSub)
    val totalStepsSub = exp(heightSub)
    val newKeyTimeSup = step / totalStepsSub
    val newKeyTimeSub = step % totalStepsSub

    def getSeed(
        seeds: (Array[Byte], Array[Byte]),
        iter: Int
    ): (Array[Byte], Array[Byte]) =
      if (iter < newKeyTimeSup) {
        val out = getSeed(prng(seeds._2), iter + 1)
        random.nextBytes(seeds._1)
        random.nextBytes(seeds._2)
        out
      } else seeds

    if (step == 0) key
    else if (step > keyTime && step < totalSteps) {
      if (keyTimeSup < newKeyTimeSup) {
        sumComposition.eraseOldNode(key._2)
        val (s1, s2) = getSeed((Array(), key._3), keyTimeSup)
        val superScheme = sumComposition.evolveKey(key._1, newKeyTimeSup)
        val newSubScheme = sumComposition.generateSecretKey(s1, heightSub)
        random.nextBytes(s1)
        val kesVkSub = sumComposition.generateVerificationKey(newSubScheme)
        val kesSigSuper = sumComposition.sign(superScheme, kesVkSub._1)
        val forwardSecureSuperScheme = eraseLeafSecretKey(superScheme)
        val updatedSubScheme =
          sumComposition.evolveKey(newSubScheme, newKeyTimeSub)
        (forwardSecureSuperScheme, updatedSubScheme, s2, kesSigSuper)
      } else {
        val subScheme = sumComposition.updateKey(key._2, newKeyTimeSub)
        (key._1, subScheme, key._3, key._4)
      }
    } else {
      throw new Error(
        s"Update error - Max steps: $totalSteps, current step: $keyTime, requested increase: $step"
      )
    }
  }

  /** @param key
    * @param m
    * @return
    */
  private[crypto] def sign(key: SK, m: Array[Byte]): SIG =
    (
      key._4,
      sumComposition.sign(key._2, m),
      sumComposition.generateVerificationKey(key._2)._1
    )

  /** Verify MMM signature
    * @param pk
    *   public key of the MMM secret key
    * @param m
    *   message corresponding to signature
    * @param sig
    *   signature to be verified
    * @return
    *   true if signature is valid false if otherwise
    */
  private[crypto] def verify(
      kesSig: SIG,
      m: Array[Byte],
      kesVk: VK
  ): Boolean = {
    val totalStepsSub = exp(kesSig._2._3.length)
    val keyTimeSup = kesVk._2 / totalStepsSub
    val keyTimeSub = kesVk._2 % totalStepsSub

    val verifySup =
      sumComposition.verify(kesSig._1, kesSig._3, (kesVk._1, keyTimeSup))
    val verifySub = sumComposition.verify(kesSig._2, m, (kesSig._3, keyTimeSub))

    verifySup && verifySub
  }
}
