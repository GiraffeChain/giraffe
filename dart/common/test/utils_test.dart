import 'package:blockchain_common/utils.dart';
import 'package:blockchain_crypto/utils.dart';
import 'package:test/test.dart';

void main() {
  group("BigInt", () {
    test("toByteArray", () {
      final i = BigInt.from(50000000);
      final bytes = i.bytes;
      expect(bytes.sameElements([2, -6, -16, -128]), true);
      final i2 = bytes.toBigInt;
      expect(i, i2);
    });
  });
}
