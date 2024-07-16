import 'dart:math';
import 'dart:typed_data';

import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/utils.dart';
import 'package:blockchain/crypto/impl/kes_helper.dart';
import 'package:blockchain/crypto/impl/kes_sum.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';

import '../utils.dart';

abstract class KesProduct {
  Future<KeyPairKesProduct> generateKeyPair(
      List<int> seed, TreeHeight height, Int64 offset);
  Future<SignatureKesProduct> sign(SecretKeyKesProduct sk, List<int> message);
  Future<bool> verify(SignatureKesProduct signature, List<int> message,
      VerificationKeyKesProduct vk);
  Future<SecretKeyKesProduct> update(SecretKeyKesProduct sk, int step);
  Future<int> getCurrentStep(SecretKeyKesProduct sk);
  Future<VerificationKeyKesProduct> generateVerificationKey(
      SecretKeyKesProduct sk);
}

class KesProductImpl extends KesProduct {
  Future<KeyPairKesProduct> generateKeyPair(
      List<int> seed, TreeHeight height, Int64 offset) async {
    final sk = await generateSecretKey(seed, height);
    final vk = await generateVerificationKey(sk);
    return KeyPairKesProduct(sk: sk, vk: vk);
  }

  Future<SignatureKesProduct> sign(
      SecretKeyKesProduct sk, List<int> message) async {
    return SignatureKesProduct()
      ..superSignature = sk.subSignature
      ..subSignature = await kesSum.sign(sk.subTree, message)
      ..subRoot =
          (await kesSum.generateVerificationKey(sk.subTree)).value.base58;
  }

  Future<bool> verify(SignatureKesProduct signature, List<int> message,
      VerificationKeyKesProduct vk) async {
    final totalStepsSub = kesHelper.exp(signature.subSignature.witness.length);
    final keyTimeSup = vk.step ~/ totalStepsSub;
    final keyTimeSub = vk.step % totalStepsSub;
    final superVerification = await kesSum.verify(
        signature.superSignature,
        signature.subRoot.decodeBase58,
        VerificationKeyKesSum(
            value: Uint8List.fromList(vk.value.decodeBase58),
            step: keyTimeSup));
    if (!superVerification) return false;
    final subVerification = await kesSum.verify(
        signature.subSignature,
        message,
        VerificationKeyKesSum(
            value: Uint8List.fromList(signature.subRoot.decodeBase58),
            step: keyTimeSub));
    return subVerification;
  }

  Future<SecretKeyKesProduct> update(SecretKeyKesProduct sk, int step) async {
    if (step == 0) return sk;
    final keyTime = await getCurrentStep(sk);
    final keyTimeSup = await kesSum.getCurrentStep(sk.superTree);
    final heightSup = kesHelper.getTreeHeight(sk.superTree);
    final heightSub = kesHelper.getTreeHeight(sk.subTree);
    final totalSteps = kesHelper.exp(heightSup + heightSub);
    final totalStepsSub = kesHelper.exp(heightSub);
    final newKeyTimeSup = step ~/ totalStepsSub;
    final newKeyTimeSub = step % totalStepsSub;

    Future<(List<int>, List<int>)> getSeed(
        (List<int>, List<int>) seeds, int iter) async {
      if (iter < newKeyTimeSup) {
        final out = getSeed(await kesHelper.prng(seeds.$2), iter + 1);
        kesHelper.overwriteBytes(seeds.$1);
        kesHelper.overwriteBytes(seeds.$2);
        return out;
      } else
        return seeds;
    }

    if (step > keyTime && step < totalSteps) {
      if (keyTimeSup < newKeyTimeSup) {
        kesSum.eraseOldNode(sk.subTree);
        final seeds = await getSeed(([], sk.nextSubSeed), keyTimeSup);
        final superScheme = await kesSum.evolveKey(sk.superTree, newKeyTimeSup);
        final newSubScheme = await kesSum.generateSecretKey(
            Uint8List.fromList(seeds.$1), heightSub);
        kesHelper.overwriteBytes(seeds.$1);
        final kesVkSub = await kesSum.generateVerificationKey(newSubScheme);
        final kesSigSuper = await kesSum.sign(superScheme, kesVkSub.value);
        final forwardSecureSuperScheme = _eraseLeafSecretKey(superScheme);
        final updatedSubScheme =
            await kesSum.evolveKey(newSubScheme, newKeyTimeSub);
        return SecretKeyKesProduct(
          superTree: forwardSecureSuperScheme,
          subTree: updatedSubScheme,
          nextSubSeed: seeds.$2,
          subSignature: kesSigSuper,
          offset: sk.offset, // TODO
        );
      } else {
        final subScheme = await kesSum.update(sk.subTree, newKeyTimeSub);
        return SecretKeyKesProduct(
          superTree: sk.superTree,
          subTree: subScheme,
          nextSubSeed: sk.nextSubSeed,
          subSignature: sk.subSignature,
          offset: sk.offset, // TODO
        );
      }
    }
    throw Exception(
        "Update error - Max steps: $totalSteps, current step: $keyTime, requested increase: $step");
  }

  Future<int> getCurrentStep(SecretKeyKesProduct sk) async {
    final numSubSteps = kesHelper.exp(kesHelper.getTreeHeight(sk.subTree));
    final tSup = await kesSum.getCurrentStep(sk.superTree);
    final tSub = await kesSum.getCurrentStep(sk.subTree);
    return (tSup * numSubSteps) + tSub;
  }

  Future<SecretKeyKesProduct> generateSecretKey(
      List<int> seed, TreeHeight height) async {
    final rSuper = await kesHelper.prng(seed);
    final rSub = await kesHelper.prng(rSuper.$2);
    final superScheme = await kesSum.generateSecretKey(rSuper.$1, height.sup);
    final subScheme = await kesSum.generateSecretKey(rSub.$1, height.sub);
    final kesVkSub = await kesSum.generateVerificationKey(subScheme);
    final kesSigSuper = await kesSum.sign(superScheme, kesVkSub.value);
    kesHelper.overwriteBytes(rSuper.$2);
    kesHelper.overwriteBytes(seed);
    return SecretKeyKesProduct(
      superTree: superScheme,
      subTree: subScheme,
      nextSubSeed: rSub.$2,
      subSignature: kesSigSuper,
      offset: Int64(0), // TODO
    );
  }

  Future<VerificationKeyKesProduct> generateVerificationKey(
      SecretKeyKesProduct sk) async {
    final superTree = sk.superTree;
    if (superTree is KesMerkleNode) {
      return VerificationKeyKesProduct()
        ..value = (await kesHelper.witness(sk.superTree)).base58
        ..step = await getCurrentStep(sk);
    } else if (superTree is KesSigningLeaf) {
      return VerificationKeyKesProduct()
        ..value = (await kesHelper.witness(sk.superTree)).base58
        ..step = 0;
    } else {
      return VerificationKeyKesProduct()
        ..value = Uint8List(32).base58
        ..step = 0;
    }
  }

  _eraseLeafSecretKey(KesBinaryTree tree) {
    if (tree is KesMerkleNode) {
      if (tree.left is KesEmpty)
        return KesMerkleNode(tree.seed, tree.witnessLeft, tree.witnessRight,
            KesEmpty(), _eraseLeafSecretKey(tree.right));
      else if (tree.right is KesEmpty) {
        return KesMerkleNode(tree.seed, tree.witnessLeft, tree.witnessRight,
            _eraseLeafSecretKey(tree.left), KesEmpty());
      }
    } else if (tree is KesSigningLeaf) {
      kesHelper.overwriteBytes(tree.sk);
      return KesSigningLeaf(Uint8List(32), tree.vk);
    }
    throw Exception("Evolving Key Configuration Error");
  }
}

final _impl = KesProductImpl();

KesProduct kesProduct = KesProductImpl();

final _generateKeyPair = _impl.generateKeyPair;
final _getCurrentStep = _impl.getCurrentStep;
final _sign = _impl.sign;
final _update = _impl.update;
final _verify = _impl.verify;
final _generateVerificationKey = _impl.generateVerificationKey;

class TreeHeight {
  final int sup;
  final int sub;

  TreeHeight(this.sup, this.sub);

  @override
  int get hashCode => Object.hash(sup, sub);

  @override
  bool operator ==(Object other) {
    if (other is TreeHeight) {
      return sup == other.sup && sub == other.sub;
    }
    return false;
  }
}

class SecretKeyKesProduct {
  final KesBinaryTree superTree;
  final KesBinaryTree subTree;
  final List<int> nextSubSeed;
  final SignatureKesSum subSignature;
  final Int64 offset;

  SecretKeyKesProduct(
      {required this.superTree,
      required this.subTree,
      required this.nextSubSeed,
      required this.subSignature,
      required this.offset});

  @override
  int get hashCode =>
      Object.hash(superTree, subTree, nextSubSeed, subSignature, offset);

  @override
  bool operator ==(Object other) {
    if (other is SecretKeyKesProduct) {
      superTree == other.superTree &&
          subTree == other.subTree &&
          nextSubSeed.sameElements(other.nextSubSeed) &&
          subSignature == other.subSignature &&
          offset == other.offset;
    }
    return false;
  }

  factory SecretKeyKesProduct.decode(Uint8List bytes) {
    final superTreeRes = _decodeTree(bytes);
    final subTreeRes = _decodeTree(superTreeRes.$2);
    final nextSubSeed = subTreeRes.$2.sublist(0, 32);
    final subSignatureRes = _decodeSignature(subTreeRes.$2.sublist(32));
    final offset = Int64.fromBytesBigEndian(subSignatureRes.$2.sublist(0, 8));
    return SecretKeyKesProduct(
      superTree: superTreeRes.$1,
      subTree: subTreeRes.$1,
      nextSubSeed: nextSubSeed,
      subSignature: subSignatureRes.$1,
      offset: offset,
    );
  }

  List<int> get encode {
    return [
      ..._encodeTree(superTree),
      ..._encodeTree(subTree),
      ...nextSubSeed,
      ..._encodeSignature(subSignature),
      ...offset.toBytesBigEndian()
    ];
  }

  List<int> _encodeTree(KesBinaryTree tree) {
    if (tree is KesMerkleNode) {
      return [
        ...[0x00],
        ...tree.seed,
        ...tree.witnessLeft,
        ...tree.witnessRight,
        ..._encodeTree(tree.left),
        ..._encodeTree(tree.right)
      ];
    } else if (tree is KesSigningLeaf) {
      return [
        ...[0x01],
        ...tree.sk,
        ...tree.vk
      ];
    } else if (tree is KesEmpty) {
      return [0x02];
    }
    throw Exception("Encoding Error");
  }

  List<int> _encodeSignature(SignatureKesSum signature) {
    final result = [
      ...signature.verificationKey.decodeBase58,
      ...signature.signature.decodeBase58,
      ...Int64(signature.witness.length).toBytesBigEndian(),
    ];
    for (final t in signature.witness) result.addAll(t.decodeBase58);
    return result;
  }

  static (KesBinaryTree, Uint8List) _decodeTree(Uint8List bytes) {
    int cursor = 1;
    if (bytes[0] == 0x00) {
      final seed = bytes.sublist(cursor, cursor += 32);
      final witnessLeft = bytes.sublist(cursor, cursor += 32);
      final witnessRight = bytes.sublist(cursor, cursor += 32);
      final left = _decodeTree(bytes.sublist(cursor));
      final right = _decodeTree(left.$2);
      return (
        KesMerkleNode(seed, witnessLeft, witnessRight, left.$1, right.$1),
        right.$2
      );
    } else if (bytes[0] == 0x01) {
      final sk = bytes.sublist(cursor, cursor += 32);
      final vk = bytes.sublist(cursor, cursor += 32);
      return (KesSigningLeaf(sk, vk), bytes.sublist(cursor));
    } else if (bytes[0] == 0x02) {
      return (KesEmpty(), bytes.sublist(1));
    }
    throw Exception("Decoding Error");
  }

  static (SignatureKesSum, List<int>) _decodeSignature(List<int> bytes) {
    int cursor = 0;
    final vk = Uint8List.fromList(bytes.sublist(cursor, cursor += 32));
    final signature = Uint8List.fromList(bytes.sublist(cursor, cursor += 64));
    Int64 witnessLength = _parseInt(bytes.sublist(cursor, cursor += 8));
    final witness = List.generate(witnessLength.toInt(), (index) {
      return Uint8List.fromList(bytes.sublist(cursor, cursor += 32));
    });

    final kesSignature = SignatureKesSum()
      ..verificationKey = vk.base58
      ..signature = signature.base58
      ..witness.addAll(witness.map((e) => e.base58));
    return (kesSignature, bytes.sublist(cursor));
  }

  static Int64 _parseInt(List<int> bytes) {
    return Int64.fromBytesBigEndian(bytes);
  }
}

class KeyPairKesProduct {
  final SecretKeyKesProduct sk;
  final VerificationKeyKesProduct vk;

  KeyPairKesProduct({required this.sk, required this.vk});

  @override
  int get hashCode => Object.hash(sk, vk);

  @override
  bool operator ==(Object other) {
    return other is KeyPairKesProduct && other.sk == sk && other.vk == vk;
  }
}

class KesProudctIsolated extends KesProduct {
  final DComputeImpl _compute;

  KesProudctIsolated(this._compute);

  @override
  Future<KeyPairKesProduct> generateKeyPair(
          List<int> seed, TreeHeight height, Int64 offset) =>
      _compute((args) => _generateKeyPair(args.$1.$1, args.$1.$2, args.$2),
          ((seed, height), offset));

  @override
  Future<int> getCurrentStep(SecretKeyKesProduct sk) =>
      _compute(_getCurrentStep, sk);

  @override
  Future<SignatureKesProduct> sign(SecretKeyKesProduct sk, List<int> message) =>
      _compute((args) => _sign(args.$1, args.$2), (sk, message));

  @override
  Future<SecretKeyKesProduct> update(SecretKeyKesProduct sk, int step) =>
      _compute((args) => _update(args.$1, args.$2), (sk, step));

  @override
  Future<bool> verify(SignatureKesProduct signature, List<int> message,
          VerificationKeyKesProduct vk) =>
      _compute((args) => _verify(args.$1.$1, args.$1.$2, args.$2),
          ((signature, message), vk));

  @override
  Future<VerificationKeyKesProduct> generateVerificationKey(
          SecretKeyKesProduct sk) =>
      _compute(_generateVerificationKey, sk);
}

// class VerificationKeyKesProduct {
//   final Uint8List value;
//   final int step;

//   VerificationKeyKesProduct({required this.value, required this.step});

//   @override
//   int get hashCode => Object.hash(value, step);

//   @override
//   bool operator ==(Object other) {
//     if (other is VerificationKeyKesProduct) {
//       return value.sameElements(other.value) && step == other.step;
//     }
//     return false;
//   }
// }

// class SignatureKesProduct {
//   final SignatureKesSum superSignature;
//   final SignatureKesSum subSignature;
//   final Uint8List subRoot;

//   SignatureKesProduct({
//     required this.superSignature,
//     required this.subSignature,
//     required this.subRoot,
//   });

//   @override
//   int get hashCode => Object.hash(superSignature, subSignature, subRoot);

//   @override
//   bool operator ==(Object other) {
//     if (other is SignatureKesProduct) {
//       return superSignature == other.superSignature &&
//           subSignature == other.subSignature &&
//           subRoot.sameElements(other.subRoot);
//     }
//     return false;
//   }
// }
