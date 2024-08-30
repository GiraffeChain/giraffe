package com.giraffechain.crypto

import munit.CatsEffectSuite
import scodec.bits.ByteVector

import java.util

class Ed25519VRFTest extends CatsEffectSuite:
  private val ed25519VRF = new Ed25519VRF
  test("test vector 3") {
    val spec = Ed25519VRFSpec(
      "c5aa8df43f9f837bedb7442f31dcb7b166d38535076f094b85ce3a2e0b4458f7",
      "fc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025",
      "af82",
      "9bc0f79119cc5604bf02d23b4caede71393cedfbb191434dd016d30177ccbf80e29dc513c01c3a980e0e545bcd848222d08a6c3e3665ff5a4cab13a643bef812e284c6b2ee063a2cb4f456794723ad0a",
      "645427e5d00c62a23fb703732fa5d892940935942101e456ecca7bb217c61c452118fec1219202a0edcf038bb6373241578be7217ba85a2687f7a0310b2df19f"
    )
    spec.verify(ed25519VRF)
  }

case class Ed25519VRFSpec(sk: Array[Byte], vk: Array[Byte], message: Array[Byte], pi: Array[Byte], beta: Array[Byte]):
  def verify(ed25519VRF: Ed25519VRF): Unit =
    val actualVk = ed25519VRF.getVerificationKey(sk)
    assert(util.Arrays.equals(actualVk, vk))
    val actualSignature = ed25519VRF.sign(sk, message)
    assert(util.Arrays.equals(actualSignature, pi))
    assert(ed25519VRF.verify(pi, message, vk))
    assert(util.Arrays.equals(ed25519VRF.proofToHash(pi), beta))

object Ed25519VRFSpec:
  def apply(skHex: String, vkHex: String, messageHex: String, piHex: String, betaHex: String): Ed25519VRFSpec =
    Ed25519VRFSpec(
      ByteVector.fromValidHex(skHex).toArray,
      ByteVector.fromValidHex(vkHex).toArray,
      ByteVector.fromValidHex(messageHex).toArray,
      ByteVector.fromValidHex(piHex).toArray,
      ByteVector.fromValidHex(betaHex).toArray
    )
