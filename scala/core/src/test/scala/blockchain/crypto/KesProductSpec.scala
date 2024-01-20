package blockchain.crypto

import munit.CatsEffectSuite

class KesProductSpec extends CatsEffectSuite {

  test("test private key 1 - generate the correct private key at a given time step") {
    val kesProduct = new KesProduct()
    val specIn_seed = "38c2775bc7e6866e69c6acd5e12ee366fd57f7df1b30e200cae610ec4ecf378c".hexStringToBytes
    val specIn_height = (1, 2)
    val specIn_time = 0
    val specOut_vk = VerificationKeyKesProduct(
      "56d4f5dc6bfe518c9b6898222c1bfc97e93f760ec48df07704369bc306884bdd".hexStringToBytes,
      specIn_time
    )

    val specOut_sk: SecretKeyKesProduct = SecretKeyKesProduct(
      constructKey(
        "0000000000000000000000000000000000000000000000000000000000000000".hexStringToBytes,
        "9077780e7a816f81b2be94b9cbed9248db8ce03545819387496047c6ad251f09".hexStringToBytes,
        (
          true,
          (
            "0000000000000000000000000000000000000000000000000000000000000000".hexStringToBytes,
            "9ec328f26f8a298c8dfd365d513301b316c09f423f111c4ab3cc84277bb1bafc".hexStringToBytes,
            "377b3bd79d099313a59dbac4fcb74cd9b45bfe6e32030e90c8f4a1dfae3bc986".hexStringToBytes
          )
        )
      ),
      constructKey(
        "57185fdef1032136515d53e1b104acbace7d9b590465c9b11a72c8943f02c7a4".hexStringToBytes,
        "d7cab746d246b5fc21b40b8778e377456a62d03636e10a0228856d61453c7595".hexStringToBytes,
        (
          true,
          (
            "0000000000000000000000000000000000000000000000000000000000000000".hexStringToBytes,
            "330daba116c2337d0b5414cc46a73506d709416c61554722b78b0b66e765443b".hexStringToBytes,
            "652c7e4997aa62a06addd75ad8a5c9d54dc9479bbb1f1045c5e5246c83318b92".hexStringToBytes
          )
        ),
        (
          false,
          (
            "c32eb1c5e9bcd3d96243e6371f52781a4f6ac6dac6976f26544c99d31f5dbecb".hexStringToBytes,
            "3726a93ad80a90eb8ef9abb49cfd954b7658fd5eb14d65e1b9b57d77253321dc".hexStringToBytes,
            "9d1f9f9d03b6ed90710c7eaf2d9156a3b34a290d7baf79e775b417336a4415d1".hexStringToBytes
          )
        )
      ),
      "d82ab9526323833262ac56f65860f38faa433ff6129c24f033e6ea786fd6db6b".hexStringToBytes,
      SignatureKesSum(
        "9077780e7a816f81b2be94b9cbed9248db8ce03545819387496047c6ad251f09".hexStringToBytes,
        "cb7af65595938758f60009dbc7312c87baef3f8f88a6babc01e392538ec331ef20766992bc91b52bedd4a2f021bbd9e10f6cd8548dd9048e56b9579cf975fe06".hexStringToBytes,
        Vector(
          "9ec328f26f8a298c8dfd365d513301b316c09f423f111c4ab3cc84277bb1bafc".hexStringToBytes
        )
      ),
      0L
    )
    val (sk, vk) = kesProduct.createKeyPair(specIn_seed, specIn_height, 0)
    val sk_t = kesProduct.update(sk, 6)
    assert(vk == specOut_vk)
    assert(sk_t == specOut_sk)
  }

  type Args = (Boolean, (Array[Byte], Array[Byte], Array[Byte]))
  def constructKey(sk: Array[Byte], vk: Array[Byte], args: Args*): KesBinaryTree =
    args.length match {
      case 0 =>
        KesBinaryTree.SigningLeaf(sk, vk)
      case _ =>
        if (args.head._1) {
          KesBinaryTree.MerkleNode(
            args.head._2._1,
            args.head._2._2,
            args.head._2._3,
            KesBinaryTree.Empty(),
            constructKey(sk, vk, args.tail*)
          )
        } else {
          KesBinaryTree.MerkleNode(
            args.head._2._1,
            args.head._2._2,
            args.head._2._3,
            constructKey(sk, vk, args.tail*),
            KesBinaryTree.Empty()
          )
        }
    }
}
