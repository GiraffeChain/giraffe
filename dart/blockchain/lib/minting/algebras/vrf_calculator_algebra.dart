import 'package:fixnum/fixnum.dart';
import 'package:rational/rational.dart';

abstract class VrfCalculatorAlgebra {
  Future<List<int>> rhoForSlot(Int64 slot, List<int> eta);
  Future<List<int>> proofForSlot(Int64 slot, List<int> eta);
  Future<List<Int64>> ineligibleSlots(
      List<int> eta, (Int64, Int64) slotRange, Rational relativeStake);
}
