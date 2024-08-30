import '../../common/models/unsigned.dart';
import 'package:rational/rational.dart';

import 'package:fixnum/fixnum.dart';

class VrfHit {
  final PartialStakerCertificate cert;
  final Int64 slot;
  final Rational threshold;

  VrfHit(this.cert, this.slot, this.threshold);
}
