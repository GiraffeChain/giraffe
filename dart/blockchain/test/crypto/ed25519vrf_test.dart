import 'dart:typed_data';

import 'package:blockchain/crypto/ed25519vrf.dart';
import 'package:blockchain/crypto/utils.dart';
import 'package:test/test.dart';
import 'package:convert/convert.dart';

void main() {
  group("Ed25519VRF", () {
    test("vector3", () async {
      final sk = _decodeUnsigned(
          "c5aa8df43f9f837bedb7442f31dcb7b166d38535076f094b85ce3a2e0b4458f7");
      final message = _decodeUnsigned("af82");
      final expectedVK = _decodeUnsigned(
          "fc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025");
      final expectedPi = _decodeUnsigned(
          "9bc0f79119cc5604bf02d23b4caede71393cedfbb191434dd016d30177ccbf80e29dc513c01c3a980e0e545bcd848222d08a6c3e3665ff5a4cab13a643bef812e284c6b2ee063a2cb4f456794723ad0a");

      final vk = await ed25519Vrf.getVerificationKey(sk);
      expect(vk.sameElements(expectedVK), true);
      final pi = await ed25519Vrf.sign(sk, message);
      expect(pi.sameElements(expectedPi), true);

      expect(await ed25519Vrf.verify(pi, message, vk), true);
      expect(await ed25519Vrf.verify(pi, message, expectedVK), true);

      expect(await ed25519Vrf.verify(expectedPi, message, vk), true);
      expect(await ed25519Vrf.verify(expectedPi, message, expectedVK), true);
    });
  });
}

Uint8List _decodeUnsigned(String h) {
  final d = hex.decode(h);
  return (d as Uint8List);
}
