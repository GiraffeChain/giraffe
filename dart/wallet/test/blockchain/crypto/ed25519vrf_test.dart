import 'dart:typed_data';

import 'package:giraffe_wallet/blockchain/crypto/ed25519vrf.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:test/test.dart';
import 'package:convert/convert.dart';

void main() {
  group("Ed25519VRF", () {
    for (int i = 0; i < _TestVector.allVectors.length; i++) {
      final vector = _TestVector.allVectors[i];
      test("Test $i", () async {
        final sk = _decodeUnsigned(vector.sk);
        final message = _decodeUnsigned(vector.message);
        final expectedVK = _decodeUnsigned(vector.vk);
        final expectedPi = _decodeUnsigned(vector.signature);
        final expectedBeta = _decodeUnsigned(vector.proofHash);
        final vk = await ed25519.getVerificationKey(sk);
        expect(vk.sameElements(expectedVK), true);
        final pi = await ed25519.sign(message, sk);
        expect(pi.sameElements(expectedPi), true);

        expect(await ed25519.verify(pi, message, vk), true);
        expect(await ed25519.verify(pi, message, expectedVK), true);

        expect(await ed25519.verify(expectedPi, message, vk), true);
        expect(await ed25519.verify(expectedPi, message, expectedVK), true);

        final beta = await ed25519Vrf.proofToHash(expectedPi);
        expect(beta.sameElements(expectedBeta), true);
      });
    }
  });
}

Uint8List _decodeUnsigned(String h) {
  final d = hex.decode(h);
  return (d as Uint8List);
}

class _TestVector {
  final String sk;
  final String vk;
  final String message;
  final String signature;
  final String proofHash;

  const _TestVector(
      this.sk, this.vk, this.message, this.signature, this.proofHash);

  static const test1 = _TestVector(
      "9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60",
      "d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a",
      "",
      "8657106690b5526245a92b003bb079ccd1a92130477671f6fc01ad16f26f723f5e8bd1839b414219e8626d393787a192241fc442e6569e96c462f62b8079b9ed83ff2ee21c90c7c398802fdeebea4001",
      "90cf1df3b703cce59e2a35b925d411164068269d7b2d29f3301c03dd757876ff66b71dda49d2de59d03450451af026798e8f81cd2e333de5cdf4f3e140fdd8ae");
  static const test2 = _TestVector(
      "4ccd089b28ff96da9db6c346ec114e0f5b8a319f35aba624da8cf6ed4fb8a6fb",
      "3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c",
      "",
      "f3141cd382dc42909d19ec5110469e4feae18300e94f304590abdced48aed593f7eaf3eb2f1a968cba3f6e23b386aeeaab7b1ea44a256e811892e13eeae7c9f6ea8992557453eac11c4d5476b1f35a08",
      "eb4440665d3891d668e7e0fcaf587f1b4bd7fbfe99d0eb2211ccec90496310eb5e33821bc613efb94db5e5b54c70a848a0bef4553a41befc57663b56373a5031");
  static const test3 = _TestVector(
      "c5aa8df43f9f837bedb7442f31dcb7b166d38535076f094b85ce3a2e0b4458f7",
      "fc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025",
      "af82",
      "9bc0f79119cc5604bf02d23b4caede71393cedfbb191434dd016d30177ccbf80e29dc513c01c3a980e0e545bcd848222d08a6c3e3665ff5a4cab13a643bef812e284c6b2ee063a2cb4f456794723ad0a",
      "645427e5d00c62a23fb703732fa5d892940935942101e456ecca7bb217c61c452118fec1219202a0edcf038bb6373241578be7217ba85a2687f7a0310b2df19f");

  static const allVectors = [test1, test2, test3];
}
