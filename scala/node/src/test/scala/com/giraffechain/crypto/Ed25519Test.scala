package com.giraffechain.crypto

import munit.CatsEffectSuite
import scodec.bits.ByteVector

import java.util

class Ed25519Test extends CatsEffectSuite:
  private val ed25519 = new Ed25519

  Specs.allSpecs.zipWithIndex.foreach((spec, index) =>
    test(s"Spec$index") {
      spec.verify(ed25519)
    }
  )

case class Spec(sk: Array[Byte], vk: Array[Byte], message: Array[Byte], signature: Array[Byte]):
  def verify(ed25519: Ed25519): Unit =
    val actualVk = ed25519.getVerificationKey(sk)
    assert(util.Arrays.equals(actualVk, vk))
    val actualSignature = ed25519.sign(sk, message)
    assert(util.Arrays.equals(actualSignature, signature))
    assert(ed25519.verify(signature, message, vk))

object Spec:
  def apply(skHex: String, vkHex: String, messageHex: String, signatureHex: String): Spec =
    if (skHex.endsWith(vkHex)) apply(skHex.substring(0, skHex.length - vkHex.length), vkHex, messageHex, signatureHex)
    else if (messageHex.nonEmpty && signatureHex.endsWith(messageHex))
      apply(skHex, vkHex, messageHex, signatureHex.substring(0, signatureHex.length - messageHex.length))
    else
      Spec(
        ByteVector.fromValidHex(skHex).toArray,
        ByteVector.fromValidHex(vkHex).toArray,
        ByteVector.fromValidHex(messageHex).toArray,
        ByteVector.fromValidHex(signatureHex).toArray
      )

object Specs:
  val test0 = Spec(
    "9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a",
    "d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a",
    "",
    "e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e065224901555fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b"
  )
  val test1 = Spec(
    "4ccd089b28ff96da9db6c346ec114e0f5b8a319f35aba624da8cf6ed4fb8a6fb3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c",
    "3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c",
    "72",
    "92a009a9f0d4cab8720e820b5f642540a2b27b5416503f8fb3762223ebdb69da085ac1e43e15996e458f3613d0f11d8c387b2eaeb4302aeeb00d291612bb0c0072"
  )
  val test2 = Spec(
    "c5aa8df43f9f837bedb7442f31dcb7b166d38535076f094b85ce3a2e0b4458f7fc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025",
    "fc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025",
    "af82",
    "6291d657deec24024827e69c3abe01a30ce548a284743a445e3680d7db5ac3ac18ff9b538d16f290ae67f760984dc6594a7c15e9716ed28dc027beceea1ec40aaf82"
  )
  val allSpecs = List(test0, test1, test2)
