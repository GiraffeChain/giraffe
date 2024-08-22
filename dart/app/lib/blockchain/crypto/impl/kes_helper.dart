import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:fixnum/fixnum.dart';
import 'package:hashlib/hashlib.dart';

import 'kes_sum.dart';

class KesHelper {
  const KesHelper();
  Future<Uint8List> hash(List<int> input) async {
    return blake2b256.convert(input).bytes;
  }

  int exp(int n) => Int64(pow(2, n).toInt()).toInt32().toInt();

  Future<(Uint8List, Uint8List)> prng(List<int> seed) async {
    final r1 = await hash([0x00]..addAll(seed));
    final r2 = await hash([0x01]..addAll(seed));
    return (r1, r2);
  }

  int getTreeHeight(KesBinaryTree tree) {
    int loop(KesBinaryTree t) {
      if (t is KesMerkleNode)
        return max(loop(t.left), loop(t.right)) + 1;
      else if (t is KesSigningLeaf)
        return 1;
      else
        return 0;
    }

    return loop(tree) - 1;
  }

  Future<Uint8List> witness(KesBinaryTree tree) async {
    if (tree is KesMerkleNode)
      return hash(tree.witnessLeft + tree.witnessRight);
    else if (tree is KesSigningLeaf)
      return hash(tree.vk);
    else
      return Uint8List(32);
  }

  overwriteBytes(List<int> bytes) {
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = SecureRandom.fast.nextInt(256) & 0xff;
    }
  }
}

const kesHelper = KesHelper();
