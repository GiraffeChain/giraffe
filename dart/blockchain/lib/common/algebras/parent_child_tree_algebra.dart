import 'package:fixnum/fixnum.dart';

abstract class ParentChildTreeAlgebra<T> {
  Future<T?> parentOf(T t);
  Future<void> assocate(T child, T parent);
  Future<Int64> heightOf(T t);
  Future<(List<T>, List<T>)> findCommmonAncestor(T a, T b);
}
