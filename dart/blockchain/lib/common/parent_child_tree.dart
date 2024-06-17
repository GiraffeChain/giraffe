import 'package:fixnum/fixnum.dart';
import 'package:ribs_core/ribs_core.dart';

abstract class ParentChildTree<T> {
  Future<T?> parentOf(T t);
  Future<void> assocate(T child, T parent);
  Future<Int64> heightOf(T t);
  Future<(IList<T>, IList<T>)> findCommmonAncestor(T a, T b);
}

class ParentChildTreeImpl<T> extends ParentChildTree<T> {
  final Future<(Int64, T)?> Function(T) read;
  final Future<void> Function(T, (Int64, T)) write;
  final T root;

  ParentChildTreeImpl(this.read, this.write, this.root);

  @override
  Future<void> assocate(T child, T parent) async {
    if (parent == root)
      await write(child, (Int64(1), parent));
    else {
      final heightId = await _readOrRaise(parent);
      await write(child, (heightId.$1 + 1, parent));
    }
  }

  @override
  Future<(IList<T>, IList<T>)> findCommmonAncestor(T a, T b) async {
    if (a == b)
      return (IList.fromDart([a]), IList.fromDart([b]));
    else {
      final aHeight = await heightOf(a);
      final bHeight = await heightOf(b);
      late List<T> aChain;
      late List<T> bChain;
      if (aHeight == bHeight) {
        aChain = [a];
        bChain = [b];
      } else if (aHeight < bHeight) {
        aChain = [a];
        bChain = (await _traverseBackToHeight([b], bHeight, aHeight)).$1;
      } else {
        aChain = (await _traverseBackToHeight([a], aHeight, bHeight)).$1;
        bChain = [b];
      }

      while (aChain.first != bChain.first) {
        aChain.insert(0, (await _readOrRaise(aChain.first)).$2);
        bChain.insert(0, (await _readOrRaise(bChain.first)).$2);
      }
      return (IList.fromDart(aChain), IList.fromDart(bChain));
    }
  }

  @override
  Future<Int64> heightOf(T t) async {
    if (t == root)
      return Int64.ZERO;
    else
      return (await _readOrRaise(t)).$1;
  }

  @override
  Future<T?> parentOf(T t) async {
    if (t == root) return null;
    final v = await read(t);
    if (v != null) return v.$2;
    return null;
  }

  Future<(Int64, T)> _readOrRaise(T id) async {
    final v = await read(id);
    if (v == null) throw Exception("Element id=$id not found");
    return v;
  }

  Future<(List<T>, Int64)> _traverseBackToHeight(
      List<T> collection, Int64 initialHeight, Int64 targetHeight) async {
    final chain = List.of(collection);
    Int64 height = initialHeight;
    while (height > targetHeight) {
      chain.insert(0, (await _readOrRaise(chain.first)).$2);
      height--;
    }
    return (chain, height);
  }
}
