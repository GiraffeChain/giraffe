package com.giraffechain.crypto

import munit.CatsEffectSuite
import scodec.bits.ByteVector
import java.util

class Ed25519Test extends CatsEffectSuite:
  private val ed25519 = new Ed25519
  test("Spec1") {
    val spec = Spec(
      "9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60",
      "d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a",
      "",
      "e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e065224901555fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b"
    )
    spec.verify(ed25519)
  }

case class Spec(sk: Array[Byte], vk: Array[Byte], message: Array[Byte], signature: Array[Byte]):
  def verify(ed25519: Ed25519): Unit =
    val actualVk = ed25519.getVerificationKey(sk)
    assert(util.Arrays.equals(actualVk, vk))
    val actualSignature = ed25519.sign(sk, message)
    assert(util.Arrays.equals(actualSignature, signature))
    assert(ed25519.verify(signature, message, vk))

object Spec:
  def apply(skHex: String, vkHex: String, messageHex: String, signatureHex: String): Spec =
    Spec(
      ByteVector.fromValidHex(skHex).toArray,
      ByteVector.fromValidHex(vkHex).toArray,
      ByteVector.fromValidHex(messageHex).toArray,
      ByteVector.fromValidHex(signatureHex).toArray
    )
