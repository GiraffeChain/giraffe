import 'package:blockchain_common/models/common.dart';
import 'package:blockchain_common/utils.dart';

class VrfArgument {
  final Eta eta;
  final Slot slot;

  VrfArgument(this.eta, this.slot);

  List<int> get signableBytes => <int>[]
    ..addAll(eta)
    ..addAll(slot.toBigInt.bytes);
}
