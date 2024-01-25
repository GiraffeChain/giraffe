import 'package:blockchain/crypto/impl/kes_sum.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group("KesSum", () {
    test(
        "Test Vector - 5 : Generate and verify a specified sum composition signature at t = [0, 10, 21, 31] using a provided seed, message, and height",
        () async {
      final specIn_seed =
          "c77bbf01a20dea8cfbd9acce52134a845c67bfd9b2cfa5c115f3a9c8597dcd03"
              .hexStringToBytes;
      final specIn_height = 5;
      final specIn_time = 0;
      final specIn_msg =
          "6d65206f72206974202d206569746865722077617920796f75206a756d70206f6666"
              .hexStringToBytes;

      final specOut_vk = VerificationKeyKesSum(
          value:
              "70c0d236d2892d1745b8c0547d93bb8ab48adbf7e4498af5dbc123a3fdf80e21"
                  .hexStringToBytes,
          step: specIn_time);
      final specOut_sig_0 = SignatureKesSum()
        ..verificationKey =
            ("bfb3bd77c3195566c00779a8a3be98e48687efb9fe0703fef255188abe3e8c86"
                .hexStringToBytes)
        ..signature =
            ("97ed7c65fce2ede533ab5476e43e2f627d3dbf2d6f0d8baeb971e7392c291fb10c4ec2b9103b7df5052fb4f7c7df0906d2c14b22770749781f85e95654e30e0b"
                .hexStringToBytes)
        ..witness.addAll([
          "2398f25f7637ae13081ba4b7674b9123f54eab960ec751a0166d76dce379b84c"
              .hexStringToBytes,
          "3ab1ccf0e083de049cfbe02e037d23ee8173af82531d8b4fd3a6ee2e4881be3d"
              .hexStringToBytes,
          "47803271bc0b85a8bee2e04ad1a2dbe7b66457d04912c65909027f794d971038"
              .hexStringToBytes,
          "a0d5cedc00c1993ea3bc06c5f8d196a1902266266d51390ef5bc15073a5be086"
              .hexStringToBytes,
          "a5ae34468d39e8c5bbf8b9427444f1d507ce5678b5a73d4d2937b0dffe190f3e"
              .hexStringToBytes
        ]);
      final specOut_sig_1 = SignatureKesSum()
        ..verificationKey =
            ("2c3893ffb5eaa06b10baab53e2302103210465f4b02a947756040606c6047920"
                .hexStringToBytes)
        ..signature =
            ("dd689f98054fb4d85c747a808a196434051a67a52e51c405d49c6153f767ef8586669525a9ebde5a4d5395c220c48fae29e6088a9e8419b38b9189eb9a78d206"
                .hexStringToBytes)
        ..witness.addAll([
          "14ec66d47c77c530382146ddffce027a7d14221f336f5ac3fc37cc369c1c19bf"
              .hexStringToBytes,
          "c8c437996395666af653895d0b1e74b2bd8771bd0c96ec78d2f3a2c6a8ad434f"
              .hexStringToBytes,
          "0c86200d9fbf50c21a5e03e2804ddacc19cb8b86e6ace577fa7813b39046c405"
              .hexStringToBytes,
          "0e036b4627a99ce67f9e94452f6837018123b354654129e19f4dbb70429eb891"
              .hexStringToBytes,
          "a5ae34468d39e8c5bbf8b9427444f1d507ce5678b5a73d4d2937b0dffe190f3e"
              .hexStringToBytes
        ]);
      final specOut_sig_2 = SignatureKesSum()
        ..verificationKey =
            ("d43476ed2380b1b96902bfaec96c1f675ad113bd55d86b506c9a26895a69b496"
                .hexStringToBytes)
        ..signature =
            ("cfd4e8a463ee8c32ca3781edeaefc4673b98631ad0b4ddfcf69baf2a5c6749734dea5401395e3c27063d1d44f13f911a7a2b738fd7bdb359ce7b4b99f8b8f90b"
                .hexStringToBytes)
        ..witness.addAll([
          "c77f68fe69b444a67b5544d59635dd5391cf065849c5f443705be9f5f080d9f5"
              .hexStringToBytes,
          "23273d7995ee43d27d4ab9320774707f50b6d2170f1648540167db548d1032ea"
              .hexStringToBytes,
          "b8439adb5dec5d6c8775cfadfc6568bd3682a08a5d328452b7823ceeff59a984"
              .hexStringToBytes,
          "8fab6b378cfa4554103345586bdf2db37897c9fdc91e0d378e16bfced6f44d82"
              .hexStringToBytes,
          "7feb24f2a47efff49217759e3e76af0def79946407710c243c19e0b4f131b326"
              .hexStringToBytes
        ]);
      final specOut_sig_3 = SignatureKesSum()
        ..verificationKey =
            ("decaf6e8f7f6c767b096775950d8f551b47f3975d5ec196d41f521850722d2c2"
                .hexStringToBytes)
        ..signature =
            ("c1e8335f8a5667138839f331310b930fddcdd61cf801a4337949e6e9470bec6ca087d26737f5641aa7ff7951abd1ed5fd5bee610763c0ea24aff7ef9dfc37809"
                .hexStringToBytes)
        ..witness.addAll([
          "4179e8cf03735b99189a37614801e8f5f608c6bd11878fd24fffc47da7b54dd0"
              .hexStringToBytes,
          "781125c39719d6c58c554d1b0203aa681db2bedf056c65897fec0faa18c770d9"
              .hexStringToBytes,
          "9cd7efa15e265d6398ca38b482ac117584c1a8bac10a39415b6fb9462b69d978"
              .hexStringToBytes,
          "6056f6e9d54b77c4c4d29b7588881938859bab939a7f7dea21d59804683edbc7"
              .hexStringToBytes,
          "7feb24f2a47efff49217759e3e76af0def79946407710c243c19e0b4f131b326"
              .hexStringToBytes
        ]);

      final keyPair =
          await kesSum.createKeyPair(specIn_seed, specIn_height, Int64.ZERO);
      final vk = keyPair.vk;
      final sk = keyPair.sk;
      final sig_0 = await kesSum.sign(sk.tree, specIn_msg);
      final sk_1 = await kesSum.update(sk.tree, 10);
      final sig_1 = await kesSum.sign(sk_1, specIn_msg);
      final vk_1 = await kesSum.generateVerificationKey(sk_1);
      final sk_2 = await kesSum.update(sk_1, 21);
      final sig_2 = await kesSum.sign(sk_2, specIn_msg);
      final vk_2 = await kesSum.generateVerificationKey(sk_2);
      final sk_3 = await kesSum.update(sk_2, 31);
      final sig_3 = await kesSum.sign(sk_3, specIn_msg);
      final vk_3 = await kesSum.generateVerificationKey(sk_3);

      expect(vk, specOut_vk);
      expect(sig_0, specOut_sig_0);
      expect(sig_1, specOut_sig_1);
      expect(sig_2, specOut_sig_2);
      expect(sig_3, specOut_sig_3);
      expect(await kesSum.verify(sig_0, specIn_msg, vk), true);
      expect(await kesSum.verify(sig_1, specIn_msg, vk_1), true);
      expect(await kesSum.verify(sig_2, specIn_msg, vk_2), true);
      expect(await kesSum.verify(sig_3, specIn_msg, vk_3), true);
    });
  });
}
