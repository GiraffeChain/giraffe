import 'dart:typed_data';

import 'package:giraffe_sdk/src/crypto/ed25519vrf.dart';
import 'package:giraffe_sdk/src/crypto/utils.dart';
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
        final vk = await ed25519Vrf.getVerificationKey(sk);
        expect(vk.sameElements(expectedVK), true);
        final pi = await ed25519Vrf.sign(sk, message);
        expect(pi.sameElements(expectedPi), true);

        expect(await ed25519Vrf.verify(pi, message, vk), true);
        expect(await ed25519Vrf.verify(pi, message, expectedVK), true);

        expect(await ed25519Vrf.verify(expectedPi, message, vk), true);
        expect(await ed25519Vrf.verify(expectedPi, message, expectedVK), true);

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
      "72",
      "f3141cd382dc42909d19ec5110469e4feae18300e94f304590abdced48aed593f7eaf3eb2f1a968cba3f6e23b386aeeaab7b1ea44a256e811892e13eeae7c9f6ea8992557453eac11c4d5476b1f35a08",
      "eb4440665d3891d668e7e0fcaf587f1b4bd7fbfe99d0eb2211ccec90496310eb5e33821bc613efb94db5e5b54c70a848a0bef4553a41befc57663b56373a5031");
  static const test3 = _TestVector(
      "c5aa8df43f9f837bedb7442f31dcb7b166d38535076f094b85ce3a2e0b4458f7",
      "fc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025",
      "af82",
      "9bc0f79119cc5604bf02d23b4caede71393cedfbb191434dd016d30177ccbf80e29dc513c01c3a980e0e545bcd848222d08a6c3e3665ff5a4cab13a643bef812e284c6b2ee063a2cb4f456794723ad0a",
      "645427e5d00c62a23fb703732fa5d892940935942101e456ecca7bb217c61c452118fec1219202a0edcf038bb6373241578be7217ba85a2687f7a0310b2df19f");

  static const test4 = _TestVector(
      "f5e5767cf153319517630f226876b86c8160cc583bc013744c6bf255f5cc0ee5",
      "278117fc144c72340f67d0f2316e8386ceffbf2b2428c9c51fef7c597f1d426e",
      "08b8b2b733424243760fe426a4b54908632110a66c2f6591eabd3345e3e4eb98fa6e264bf09efe12ee50f8f54e9f77b1e355f6c50544e23fb1433ddf73be84d879de7c0046dc4996d9e773f4bc9efe5738829adb26c81b37c93a1b270b20329d658675fc6ea534e0810a4432826bf58c941efb65d57a338bbd2e26640f89ffbc1a858efcb8550ee3a5e1998bd177e93a7363c344fe6b199ee5d02e82d522c4feba15452f80288a821a579116ec6dad2b3b310da903401aa62100ab5d1a36553e06203b33890cc9b832f79ef80560ccb9a39ce767967ed628c6ad573cb116dbefefd75499da96bd68a8a97b928a8bbc103b6621fcde2beca1231d206be6cd9ec7aff6f6c94fcd7204ed3455c68c83f4a41da4af2b74ef5c53f1d8ac70bdcb7ed185ce81bd84359d44254d95629e9855a94a7c1958d1f8ada5d0532ed8a5aa3fb2d17ba70eb6248e594e1a2297acbbb39d502f1a8c6eb6f1ce22b3de1a1f40cc24554119a831a9aad6079cad88425de6bde1a9187ebb6092cf67bf2b13fd65f27088d78b7e883c8759d2c4f5c65adb7553878ad575f9fad878e80a0c9ba63bcbcc2732e69485bbc9c90bfbd62481d9089beccf80cfe2df16a2cf65bd92dd597b0707e0917af48bbb75fed413d238f5555a7a569d80c3414a8d0859dc65a46128bab27af87a71314f318c782b23ebfe808b82b0ce26401d2e22f04d83d1255dc51addd3b75a2b1ae0784504df543af8969be3ea7082ff7fc9888c144da2af58429ec96031dbcad3dad9af0dcbaaaf268cb8fcffead94f3c7ca495e056a9b47acdb751fb73e666c6c655ade8297297d07ad1ba5e43f1bca32301651339e22904cc8c42f58c30c04aafdb038dda0847dd988dcda6f3bfd15c4b4c4525004aa06eeff8ca61783aacec57fb3d1f92b0fe2fd1a85f6724517b65e614ad6808d6f6ee34dff7310fdc82aebfd904b01e1dc54b2927094b2db68d6f903b68401adebf5a7e08d78ff4ef5d63653a65040cf9bfd4aca7984a74d37145986780fc0b16ac451649de6188a7dbdf191f64b5fc5e2ab47b57f7f7276cd419c17a3ca8e1b939ae49e488acba6b965610b5480109c8b17b80e1b7b750dfc7598d5d5011fd2dcc5600a32ef5b52a1ecc820e308aa342721aac0943bf6686b64b2579376504ccc493d97e6aed3fb0f9cd71a43dd497f01f17c0e2cb3797aa2a2f256656168e6c496afc5fb93246f6b1116398a346f1a641f3b041e989f7914f90cc2c7fff357876e506b50d334ba77c225bc307ba537152f3f1610e4eafe595f6d9d90d11faa933a15ef1369546868a7f3a45a96768d40fd9d03412c091c6315cf4fde7cb68606937380db2eaaa707b4c4185c32eddcdd306705e4dc1ffc872eeee475a64dfac86aba41c0618983f8741c5ef68d3a101e8a3b8cac60c905c15fc910840b94c00a0b9d0",
      "318d2b0bfcc1a1ced8abced025e420e3c59c0c89b214b2251fefbb401fd3421e0d6104a24c1558dde8cbe0647d1b31931799128526bd9b75b39ad8475ec59ce66363b230d5b7831aac57a941c8f62f04",
      "0b17d96088846eaf414b2febb10a4d676e0215a8926b19eb7299654a28544f1b32ea00a0672515a1863c30776fbed4ad1b9632c98fcf017edcd2f403e2428794");

  static const allVectors = [test1, test2, test3, test4];
}
