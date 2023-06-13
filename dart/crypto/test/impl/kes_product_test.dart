import 'dart:typed_data';

import 'package:blockchain_crypto/impl/kes_product.dart';
import 'package:blockchain_crypto/impl/kes_sum.dart';
import 'package:blockchain_crypto/kes.dart';
import 'package:blockchain_crypto/utils.dart';
import 'package:fixnum/fixnum.dart';
import 'package:fpdart/fpdart.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group("KesProduct", () {
    test("vector1", () async {
      final specIn_seed =
          "38c2775bc7e6866e69c6acd5e12ee366fd57f7df1b30e200cae610ec4ecf378c"
              .hexStringToBytes;
      final specIn_height = TreeHeight(1, 2);
      final specIn_time = 0;
      final specOut_vk = VerificationKeyKesProduct(
          value:
              "56d4f5dc6bfe518c9b6898222c1bfc97e93f760ec48df07704369bc306884bdd"
                  .hexStringToBytes,
          step: specIn_time);
      final specOut_sk = SecretKeyKesProduct(
        superTree: _buildTestTree(
          "0000000000000000000000000000000000000000000000000000000000000000"
              .hexStringToBytes,
          "9077780e7a816f81b2be94b9cbed9248db8ce03545819387496047c6ad251f09"
              .hexStringToBytes,
          [
            TestTreeArg(
              true,
              "0000000000000000000000000000000000000000000000000000000000000000"
                  .hexStringToBytes,
              "9ec328f26f8a298c8dfd365d513301b316c09f423f111c4ab3cc84277bb1bafc"
                  .hexStringToBytes,
              "377b3bd79d099313a59dbac4fcb74cd9b45bfe6e32030e90c8f4a1dfae3bc986"
                  .hexStringToBytes,
            ),
          ],
        ),
        subTree: _buildTestTree(
          "57185fdef1032136515d53e1b104acbace7d9b590465c9b11a72c8943f02c7a4"
              .hexStringToBytes,
          "d7cab746d246b5fc21b40b8778e377456a62d03636e10a0228856d61453c7595"
              .hexStringToBytes,
          [
            TestTreeArg(
              true,
              "0000000000000000000000000000000000000000000000000000000000000000"
                  .hexStringToBytes,
              "330daba116c2337d0b5414cc46a73506d709416c61554722b78b0b66e765443b"
                  .hexStringToBytes,
              "652c7e4997aa62a06addd75ad8a5c9d54dc9479bbb1f1045c5e5246c83318b92"
                  .hexStringToBytes,
            ),
            TestTreeArg(
              false,
              "c32eb1c5e9bcd3d96243e6371f52781a4f6ac6dac6976f26544c99d31f5dbecb"
                  .hexStringToBytes,
              "3726a93ad80a90eb8ef9abb49cfd954b7658fd5eb14d65e1b9b57d77253321dc"
                  .hexStringToBytes,
              "9d1f9f9d03b6ed90710c7eaf2d9156a3b34a290d7baf79e775b417336a4415d1"
                  .hexStringToBytes,
            ),
          ],
        ),
        nextSubSeed:
            "d82ab9526323833262ac56f65860f38faa433ff6129c24f033e6ea786fd6db6b"
                .hexStringToBytes,
        subSignature: SignatureKesSum(
            vk: "9077780e7a816f81b2be94b9cbed9248db8ce03545819387496047c6ad251f09"
                .hexStringToBytes,
            signature:
                "cb7af65595938758f60009dbc7312c87baef3f8f88a6babc01e392538ec331ef20766992bc91b52bedd4a2f021bbd9e10f6cd8548dd9048e56b9579cf975fe06"
                    .hexStringToBytes,
            witness: [
              "9ec328f26f8a298c8dfd365d513301b316c09f423f111c4ab3cc84277bb1bafc"
                  .hexStringToBytes
            ]),
        offset: Int64.ZERO,
      );

      final keyPair = await kesProduct.generateKeyPair(
          specIn_seed, specIn_height, Int64.ZERO);
      expect(keyPair.vk, specOut_vk);
      final sk_t = await kesProduct.update(keyPair.sk, 6);
      expect(_skEqual(sk_t, specOut_sk), true);
    });

    test(
        "Test Vector - 1 - Generate and verify a specified product composition signature at t = [0, 1, 2, 3] using a provided seed, message, and heights of the two trees",
        () async {
      final kesProduct = KesProductImpl();
      final specIn_seed =
          "2a6367c85f416ccef46a4521004228f74f24f7b0770ecced07c0dc035135bf6f"
              .hexStringToBytes;
      final specIn_height = TreeHeight(1, 1);
      final specIn_time = 0;
      final specIn_msg =
          "697420617320646f206265206974206865206d65206f72".hexStringToBytes;

      final specOut_vk = VerificationKeyKesProduct(
          value:
              "47099c36fc71c2aae79046c65bb5d3f2c79d058bddd346370bfd22c6263d438d"
                  .hexStringToBytes,
          step: specIn_time);

      final specOut_sig_0 = SignatureKesProduct(
          superSignature: SignatureKesSum(
              vk: ("d1a38e6db07062c9c58036c537d1c999b6fc8b60c51feeede25afda66ee36395"
                  .hexStringToBytes),
              signature:
                  ("e23e79815bf3faa96c786a2e7a22379b0f14d578aec4b2d31c225bd145dfc0b7041fd4a4dfff26f5214a168eccd9f416fdaeba6cf15784cc7451562550904109"
                      .hexStringToBytes),
              witness: [
                "babb43bba46bb63fc0d7f0c460733f1835b23ec59cbf89b42b8ee5090616ba2e"
                    .hexStringToBytes
              ]),
          subSignature: SignatureKesSum(
              vk: ("1747b2fffbeccefa8a855bb28af7f7e8937bc5e24972bf49a9ad1cf26168ef54"
                  .hexStringToBytes),
              signature:
                  ("4b6fb021e285e7f7408c3c80bd8217e8edcb5623e02f12956d32d9412caa1e995dd1400e3a638280aeba1aed909be2021c48d63dd966be1b52012b5ad392740b"
                      .hexStringToBytes),
              witness: [
                "07586219db5738b54be24aec04f8f51f1d84a1531860135f9bcc4fbe3bc51a55"
                    .hexStringToBytes
              ]),
          subRoot:
              "d86d2201174bea618cdae1f62f0be718e9cff353dea2d4da710652d2011727a4"
                  .hexStringToBytes);

      final specOut_sig_1 = SignatureKesProduct(
          superSignature: SignatureKesSum(
              vk: ("d1a38e6db07062c9c58036c537d1c999b6fc8b60c51feeede25afda66ee36395"
                  .hexStringToBytes),
              signature:
                  ("e23e79815bf3faa96c786a2e7a22379b0f14d578aec4b2d31c225bd145dfc0b7041fd4a4dfff26f5214a168eccd9f416fdaeba6cf15784cc7451562550904109"
                      .hexStringToBytes),
              witness: [
                "babb43bba46bb63fc0d7f0c460733f1835b23ec59cbf89b42b8ee5090616ba2e"
                    .hexStringToBytes
              ]),
          subSignature: SignatureKesSum(
              vk: ("d21551b12cf35d9b6022742352d6d5574b4f07f2cbab7f4cff25e43028b46aba"
                  .hexStringToBytes),
              signature:
                  ("0517a4e29b8196ddfc1761fa2224b70cfc1b1b80b96faed4826a0aee80dfb1da770fe310fdf5cd596f5ad34920e6eff15fe02d5fa4fbae79e2d3db1fee68cb02"
                      .hexStringToBytes),
              witness: [
                "a2fc1f14fa2c724cf2972d030fca6f1adf78490018760fa3e3b5ad46279b47e1"
                    .hexStringToBytes
              ]),
          subRoot:
              "d86d2201174bea618cdae1f62f0be718e9cff353dea2d4da710652d2011727a4"
                  .hexStringToBytes);

      final specOut_sig_2 = SignatureKesProduct(
          superSignature: SignatureKesSum(
              vk: "4e66fe180d5cd03c1593d2295cb21e4fbbca8d0c5fe7dbf3372a9ee6f9f1f8ae"
                  .hexStringToBytes,
              signature:
                  "e69d7a6ae2164e20487400d4fb10d96a2fdb37501462bb5baf7a3cc0682f7eae95aab47c5eb6a9772a77768627a36641a47c92baca75cdde404e9bfae0301d02"
                      .hexStringToBytes,
              witness: [
                "9417bf4a4456a865a92ec1cc0c50bf0f90d1f1c09f79ab80485a48ca975375e1"
                    .hexStringToBytes
              ]),
          subSignature: SignatureKesSum(
              vk: "ec4a9f15574d260f9c41b0c847c08237a3f590e21bd9267bc72f25d1476ba338"
                  .hexStringToBytes,
              signature:
                  "7851eac4378709e78f8fc0cf17ddc7b6883670a31d1fb5fdd45b1f3a656988cd60d13c7b93095f9ce4b0e5c48dd79282761e542bfa187ff7c09619af5c7ef305"
                      .hexStringToBytes,
              witness: [
                "d21e09026215b55fc6c295a7fb239f3c37b558a5a19cdcb10fefc9b65201d8df"
                    .hexStringToBytes
              ]),
          subRoot:
              "4f9618b4e9bdfecb43d5038cee3f1eea092a29244ee7d36da3d1a828efe8efdb"
                  .hexStringToBytes);

      final specOut_sig_3 = SignatureKesProduct(
          superSignature: SignatureKesSum(
              vk: "4e66fe180d5cd03c1593d2295cb21e4fbbca8d0c5fe7dbf3372a9ee6f9f1f8ae"
                  .hexStringToBytes,
              signature:
                  "e69d7a6ae2164e20487400d4fb10d96a2fdb37501462bb5baf7a3cc0682f7eae95aab47c5eb6a9772a77768627a36641a47c92baca75cdde404e9bfae0301d02"
                      .hexStringToBytes,
              witness: [
                "9417bf4a4456a865a92ec1cc0c50bf0f90d1f1c09f79ab80485a48ca975375e1"
                    .hexStringToBytes
              ]),
          subSignature: SignatureKesSum(
              vk: "be533ba32cdc053b51218abc6ce3ebe66a9c0aa6f8be97930d9abe0b370d264e"
                  .hexStringToBytes,
              signature:
                  "1fd2812b224d955f2444d1d8988704c83cee284c1f023b4f9696ef2d0c19db69c75379e3a470658c67cb308dcc72f3c2e89825be9363cae3e0c91020f495e90f"
                      .hexStringToBytes,
              witness: [
                "af810b4355fc79ca2e1b27285a6dde3b725404b3937c7e120c499415375e79d8"
                    .hexStringToBytes
              ]),
          subRoot:
              "4f9618b4e9bdfecb43d5038cee3f1eea092a29244ee7d36da3d1a828efe8efdb"
                  .hexStringToBytes);

      final keyPair = await kesProduct.generateKeyPair(
          specIn_seed, specIn_height, Int64.ZERO);
      final sk = keyPair.sk;
      final vk = keyPair.vk;
      expect(vk, specOut_vk);
      final sig_0 = await kesProduct.sign(sk, specIn_msg);
      expect(sig_0, specOut_sig_0);
      expect(await kesProduct.verify(sig_0, specIn_msg, vk), true);
      final sk_1 = await kesProduct.update(sk, 1);
      final vk_1 = await kesProduct.generateVerificationKey(sk_1);
      final sig_1 = await kesProduct.sign(sk_1, specIn_msg);
      expect(sig_1, specOut_sig_1);
      expect(await kesProduct.verify(sig_1, specIn_msg, vk_1), true);
      final sk_2 = await kesProduct.update(sk_1, 2);
      final vk_2 = await kesProduct.generateVerificationKey(sk_2);
      final sig_2 = await kesProduct.sign(sk_2, specIn_msg);
      expect(sig_2, specOut_sig_2);
      expect(await kesProduct.verify(sig_2, specIn_msg, vk_2), true);
      final sk_3 = await kesProduct.update(sk_2, 3);
      final vk_3 = await kesProduct.generateVerificationKey(sk_3);
      final sig_3 = await kesProduct.sign(sk_3, specIn_msg);
      expect(sig_3, specOut_sig_3);
      expect(await kesProduct.verify(sig_3, specIn_msg, vk_3), true);
    });
  });
}

class TestTreeArg {
  final bool leftRight;
  final Uint8List seed;
  final Uint8List witnessLeft;
  final Uint8List witnessRight;

  TestTreeArg(this.leftRight, this.seed, this.witnessLeft, this.witnessRight);
}

KesBinaryTree _buildTestTree(
    Uint8List sk, Uint8List vk, Iterable<TestTreeArg> args) {
  if (args.isEmpty) return KesSigningLeaf(sk, vk);
  final arg0 = args.first;
  if (arg0.leftRight)
    return KesMerkleNode(arg0.seed, arg0.witnessLeft, arg0.witnessRight,
        KesEmpty(), _buildTestTree(sk, vk, args.tail.toNullable()!));
  return KesMerkleNode(arg0.seed, arg0.witnessLeft, arg0.witnessRight,
      _buildTestTree(sk, vk, args.tail.toNullable()!), KesEmpty());
}

bool _skEqual(SecretKeyKesProduct sk1, SecretKeyKesProduct sk2) {
  return _treeEqual(sk1.superTree, sk2.superTree) &&
      _treeEqual(sk1.subTree, sk2.subTree) &&
      sk1.nextSubSeed.sameElements(sk2.nextSubSeed) &&
      (sk1.subSignature == sk2.subSignature) &&
      sk1.offset == sk2.offset;
}

bool _treeEqual(KesBinaryTree a, KesBinaryTree b) {
  if (a is KesMerkleNode && b is KesMerkleNode) {
    return a.seed.sameElements(b.seed) &&
        a.witnessLeft.sameElements(b.witnessLeft) &&
        a.witnessRight.sameElements(b.witnessRight) &&
        _treeEqual(a.left, b.left) &&
        _treeEqual(a.right, b.right);
  } else if (a is KesSigningLeaf && b is KesSigningLeaf) {
    return a.sk.sameElements(b.sk) && a.vk.sameElements(b.vk);
  } else if (a is KesEmpty && b is KesEmpty) {
    return true;
  } else {
    return false;
  }
}
