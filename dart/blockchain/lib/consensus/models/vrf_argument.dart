import 'package:blockchain/common/models/common.dart';
import 'package:blockchain/common/utils.dart';
import 'package:blockchain/crypto/utils.dart';

class VrfArgument {
  final Eta eta;
  final Slot slot;

  VrfArgument(this.eta, this.slot);

  List<int> get signableBytes => [...eta, ...slot.toBytesBigEndian()];

  @override
  int get hashCode => Object.hash(eta, slot);

  @override
  bool operator ==(Object other) {
    if (other is VrfArgument) {
      eta.sameElements(other.eta) && slot == other.slot;
    }
    return false;
  }
}
