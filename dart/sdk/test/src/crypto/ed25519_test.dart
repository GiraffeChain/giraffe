import 'dart:typed_data';

import 'package:giraffe_sdk/sdk.dart';
import 'package:test/test.dart';
import 'package:convert/convert.dart';

void main() {
  group("Ed25519", () {
    for (int i = 0; i < _TestVector.allVectors.length; i++) {
      final vector = _TestVector.allVectors[i].stripped;
      test("Test $i", () async {
        final sk = _decodeUnsigned(vector.sk);
        final message = _decodeUnsigned(vector.message);
        final expectedVK = _decodeUnsigned(vector.vk);
        final expectedPi = _decodeUnsigned(vector.signature);
        final vk = await ed25519.getVerificationKey(sk);
        expect(vk.sameElements(expectedVK), true);
        final pi = await ed25519.sign(message, sk);
        expect(pi.sameElements(expectedPi), true);

        expect(await ed25519.verify(pi, message, vk), true);
        expect(await ed25519.verify(pi, message, expectedVK), true);

        expect(await ed25519.verify(expectedPi, message, vk), true);
        expect(await ed25519.verify(expectedPi, message, expectedVK), true);
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

  const _TestVector(this.sk, this.vk, this.message, this.signature);

  _TestVector get stripped {
    var sk = this.sk;
    if (sk.endsWith(vk)) {
      sk = sk.substring(0, sk.length - vk.length);
    }
    var signature = this.signature;
    if (signature.endsWith(message)) {
      signature = signature.substring(0, signature.length - message.length);
    }
    return _TestVector(sk, vk, message, signature);
  }

  static const test1 = _TestVector(
    "9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a",
    "d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a",
    "",
    "e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e065224901555fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b",
  );

  static const test2 = _TestVector(
    "4ccd089b28ff96da9db6c346ec114e0f5b8a319f35aba624da8cf6ed4fb8a6fb3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c",
    "3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c",
    "72",
    "92a009a9f0d4cab8720e820b5f642540a2b27b5416503f8fb3762223ebdb69da085ac1e43e15996e458f3613d0f11d8c387b2eaeb4302aeeb00d291612bb0c0072",
  );

  static const test3 = _TestVector(
    "c5aa8df43f9f837bedb7442f31dcb7b166d38535076f094b85ce3a2e0b4458f7fc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025",
    "fc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025",
    "af82",
    "6291d657deec24024827e69c3abe01a30ce548a284743a445e3680d7db5ac3ac18ff9b538d16f290ae67f760984dc6594a7c15e9716ed28dc027beceea1ec40aaf82",
  );

  static const allVectors = [test1, test2, test3];
}
