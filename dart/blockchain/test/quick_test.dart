import 'package:blockchain/common/utils.dart';
import 'package:hashlib/hashlib.dart';
import 'package:rational/rational.dart';

void main() {
  final r = BigInt.from(534795345).bytesBigEndian;
  r;

  final threshold = Rational(BigInt.from(534795345), BigInt.from(153634755855));
  final evidence = blake2b256
      .convert(threshold.numerator.bytesBigEndian +
          threshold.denominator.bytesBigEndian)
      .bytes;
  evidence;
}
