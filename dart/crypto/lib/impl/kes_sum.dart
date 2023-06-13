import 'dart:typed_data';

import 'package:blockchain_crypto/ed25519.dart';
import 'package:blockchain_crypto/impl/kes_helper.dart';
import 'package:blockchain_crypto/utils.dart';
import 'package:fixnum/fixnum.dart';
import 'package:fpdart/fpdart.dart';

/**
 * Credit to Aaron Schutza
 */
class KesSum {
  const KesSum();
  Future<KeyPairKesSum> createKeyPair(
      Uint8List seed, int height, Int64 offset) async {
    final tree = await generateSecretKey(seed, height);
    final vk = await generateVerificationKey(tree);
    return KeyPairKesSum(
        sk: SecretKeyKesSum(tree: tree, offset: offset), vk: vk);
  }

  Future<SignatureKesSum> sign(KesBinaryTree skTree, List<int> message) async {
    Future<SignatureKesSum> loop(
        KesBinaryTree keyTree, List<List<int>> W) async {
      if (keyTree is KesMerkleNode) {
        if (keyTree.left is KesEmpty)
          return loop(keyTree.right, [List.of(keyTree.witnessLeft)]..addAll(W));
        else
          return loop(keyTree.left, [List.of(keyTree.witnessRight)]..addAll(W));
      } else if (keyTree is KesSigningLeaf) {
        return SignatureKesSum(
            vk: Uint8List.fromList(keyTree.vk),
            signature:
                Uint8List.fromList(await ed25519.sign(message, keyTree.sk)),
            witness: W.map(Uint8List.fromList).toList());
      } else {
        return SignatureKesSum(
            vk: Uint8List(32),
            signature: Uint8List(64),
            witness: [Uint8List(0)]);
      }
    }

    return loop(skTree, []);
  }

  Future<bool> verify(SignatureKesSum signature, List<int> message,
      VerificationKeyKesSum vk) async {
    bool leftGoing(int level) => ((vk.step ~/ kesHelper.exp(level)) % 2) == 0;
    Future<bool> emptyWitness() async =>
        vk.value.sameElements(await kesHelper.hash(signature.vk));
    Future<bool> singleWitness(List<int> witness) async {
      final hashVkSign = await kesHelper.hash(signature.vk);
      if (leftGoing(0)) {
        return vk.value
            .sameElements(await kesHelper.hash(hashVkSign + witness));
      } else
        return vk.value
            .sameElements(await kesHelper.hash(witness + hashVkSign));
    }

    Future<bool> multiWitness(List<List<int>> witnessList,
        List<int> witnessLeft, List<int> witnessRight, int index) async {
      if (witnessList.isEmpty)
        return vk.value
            .sameElements(await kesHelper.hash(witnessLeft + witnessRight));
      else if (leftGoing(index))
        return multiWitness(
          witnessList.sublist(1),
          await kesHelper.hash(witnessLeft + witnessRight),
          witnessList.first,
          index + 1,
        );
      else
        return multiWitness(
          witnessList.sublist(1),
          witnessList.first,
          await kesHelper.hash(witnessLeft + witnessRight),
          index + 1,
        );
    }

    Future<bool> verifyMerkle(List<List<int>> W) async {
      if (W.isEmpty)
        return emptyWitness();
      else if (W.length == 1)
        return singleWitness(W.first);
      else if (leftGoing(0))
        return multiWitness(
            W.sublist(1), await kesHelper.hash(signature.vk), W.first, 1);
      else
        return multiWitness(
            W.sublist(1), W.first, await kesHelper.hash(signature.vk), 1);
    }

    final ed25519Verification =
        await ed25519.verify(signature.signature, message, signature.vk);
    if (!ed25519Verification) return false;

    final merkleVerification = await verifyMerkle(signature.witness);
    return merkleVerification;
  }

  Future<KesBinaryTree> update(KesBinaryTree tree, int step) async {
    if (step == 0) return tree;
    final totalSteps = kesHelper.exp(kesHelper.getTreeHeight(tree));
    final keyTime = getCurrentStep(tree);
    if (step < totalSteps && keyTime < step) {
      return await evolveKey(tree, step);
    }
    throw Exception(
        "Update error - Max steps: $totalSteps, current step: $keyTime, requested increase: $step");
  }

  int getCurrentStep(KesBinaryTree tree) {
    if (tree is KesMerkleNode) {
      if (tree.left is KesEmpty && tree.right is KesSigningLeaf)
        return 1;
      else if (tree.left is KesEmpty && tree.right is KesMerkleNode)
        return getCurrentStep(tree.right) +
            kesHelper.exp(kesHelper.getTreeHeight(tree.right));
      else if (tree.right is KesEmpty) return getCurrentStep(tree.left);
    }
    return 0;
  }

  Future<KesBinaryTree> generateSecretKey(Uint8List seed, int height) async {
    Future<KesBinaryTree> seedTree(Uint8List seed, int height) async {
      if (height == 0) {
        final keyPair = await ed25519.generateKeyPairFromSeed(seed);
        return KesSigningLeaf(
            Uint8List.fromList(keyPair.sk), Uint8List.fromList(keyPair.vk));
      } else {
        final r = await kesHelper.prng(seed);
        final left = await seedTree(r.first, height - 1);
        final right = await seedTree(r.second, height - 1);
        return KesMerkleNode(r.second, await kesHelper.witness(left),
            await kesHelper.witness(right), left, right);
      }
    }

    KesBinaryTree reduceTree(KesBinaryTree fullTree) {
      if (fullTree is KesMerkleNode) {
        eraseOldNode(fullTree.right);
        return KesMerkleNode(fullTree.seed, fullTree.witnessLeft,
            fullTree.witnessRight, reduceTree(fullTree.left), KesEmpty());
      } else {
        return fullTree;
      }
    }

    final out = reduceTree(await seedTree(seed, height));
    kesHelper.overwriteBytes(seed);
    return out;
  }

  Future<VerificationKeyKesSum> generateVerificationKey(
      KesBinaryTree tree) async {
    if (tree is KesMerkleNode) {
      return VerificationKeyKesSum(
          value: await kesHelper.witness(tree), step: getCurrentStep(tree));
    } else if (tree is KesSigningLeaf) {
      return VerificationKeyKesSum(
          value: await kesHelper.witness(tree), step: 0);
    } else {
      return VerificationKeyKesSum(value: Uint8List(32), step: 0);
    }
  }

  void eraseOldNode(KesBinaryTree node) {
    if (node is KesMerkleNode) {
      kesHelper.overwriteBytes(node.seed);
      kesHelper.overwriteBytes(node.witnessLeft);
      kesHelper.overwriteBytes(node.witnessRight);
      eraseOldNode(node.left);
      eraseOldNode(node.right);
    } else if (node is KesSigningLeaf) {
      kesHelper.overwriteBytes(node.sk);
      kesHelper.overwriteBytes(node.vk);
    }
  }

  Future<KesBinaryTree> evolveKey(KesBinaryTree input, int step) async {
    final halfTotalSteps = kesHelper.exp(kesHelper.getTreeHeight(input) - 1);
    shiftStep(int step) => step % halfTotalSteps;
    if (step >= halfTotalSteps) {
      if (input is KesMerkleNode) {
        if (input.left is KesSigningLeaf && input.right is KesEmpty) {
          final keyPair = await ed25519.generateKeyPairFromSeed(input.seed);
          final newNode = KesMerkleNode(
              Uint8List(input.seed.length),
              input.witnessLeft,
              input.witnessRight,
              KesEmpty(),
              KesSigningLeaf(Uint8List.fromList(keyPair.sk),
                  Uint8List.fromList(keyPair.vk)));
          eraseOldNode(input.left);
          kesHelper.overwriteBytes(input.seed);
          return newNode;
        }
        if (input.left is KesMerkleNode && input.right is KesEmpty) {
          final newNode = KesMerkleNode(
            Uint8List(input.seed.length),
            input.witnessLeft,
            input.witnessRight,
            KesEmpty(),
            await evolveKey(
                await generateSecretKey(
                    input.seed, kesHelper.getTreeHeight(input) - 1),
                shiftStep(step)),
          );
          eraseOldNode(input.left);
          kesHelper.overwriteBytes(input.seed);
          return newNode;
        }
        if (input.left is KesEmpty) {
          return KesMerkleNode(
              input.seed,
              input.witnessLeft,
              input.witnessRight,
              KesEmpty(),
              await evolveKey(input.right, shiftStep(step)));
        }
      } else if (input is KesSigningLeaf)
        return input;
      else
        return KesEmpty();
    } else {
      if (input is KesMerkleNode && input.right is KesEmpty) {
        return KesMerkleNode(input.seed, input.witnessLeft, input.witnessRight,
            await evolveKey(input.left, shiftStep(step)), KesEmpty());
      } else if (input is KesMerkleNode && input.left is KesEmpty) {
        return KesMerkleNode(input.seed, input.witnessLeft, input.witnessRight,
            KesEmpty(), await evolveKey(input.right, shiftStep(step)));
      } else if (input is KesSigningLeaf) {
        return input;
      }
      return KesEmpty();
    }
    return KesEmpty();
  }
}

const kesSum = KesSum();

abstract class KesBinaryTree {}

class KesMerkleNode extends KesBinaryTree {
  final Uint8List seed;
  final Uint8List witnessLeft;
  final Uint8List witnessRight;
  final KesBinaryTree left;
  final KesBinaryTree right;

  KesMerkleNode(
      this.seed, this.witnessLeft, this.witnessRight, this.left, this.right);

  @override
  int get hashCode => Object.hash(seed, witnessLeft, witnessRight, left, right);

  @override
  bool operator ==(Object other) {
    if (other is KesMerkleNode) {
      return seed.sameElements(other.seed) &&
          witnessLeft.sameElements(other.witnessLeft) &&
          witnessRight.sameElements(other.witnessRight) &&
          left == other.left &&
          right == other.right;
    }
    return false;
  }
}

class KesSigningLeaf extends KesBinaryTree {
  final Uint8List sk;
  final Uint8List vk;

  KesSigningLeaf(this.sk, this.vk);

  @override
  int get hashCode => Object.hash(sk, vk);

  @override
  bool operator ==(Object other) {
    if (other is KesSigningLeaf) {
      return sk.sameElements(other.sk) && vk.sameElements(other.vk);
    }
    return false;
  }
}

class KesEmpty extends KesBinaryTree {
  @override
  int get hashCode => 0;

  @override
  bool operator ==(Object other) {
    if (other is KesEmpty) {
      return true;
    }
    return false;
  }
}

class SecretKeyKesSum {
  final KesBinaryTree tree;
  final Int64 offset;

  SecretKeyKesSum({required this.tree, required this.offset});

  @override
  int get hashCode => Object.hash(tree, offset);

  @override
  bool operator ==(Object other) {
    if (other is SecretKeyKesSum) {
      return tree == other.tree && offset == other.offset;
    }
    return false;
  }
}

class VerificationKeyKesSum {
  final Uint8List value;
  final int step;

  VerificationKeyKesSum({required this.value, required this.step});
  @override
  int get hashCode => Object.hash(value, step);

  @override
  bool operator ==(Object other) {
    if (other is VerificationKeyKesSum) {
      return value.sameElements(other.value) && step == other.step;
    }
    return false;
  }
}

class KeyPairKesSum {
  final SecretKeyKesSum sk;
  final VerificationKeyKesSum vk;

  KeyPairKesSum({required this.sk, required this.vk});

  @override
  int get hashCode => Object.hash(sk, vk);

  @override
  bool operator ==(Object other) {
    if (other is KeyPairKesSum) {
      return sk == other.sk && vk == other.vk;
    }
    return false;
  }
}

class SignatureKesSum {
  final Uint8List vk;
  final Uint8List signature;
  final List<Uint8List> witness;

  SignatureKesSum({
    required this.vk,
    required this.signature,
    required this.witness,
  });

  @override
  int get hashCode => Object.hash(vk, signature, witness);

  @override
  bool operator ==(Object other) {
    if (other is SignatureKesSum) {
      return vk.sameElements(other.vk) &&
          signature.sameElements(other.signature) &&
          witness.length == other.witness.length &&
          witness.zip(other.witness).all((t) => t.first.sameElements(t.second));
    }
    return false;
  }
}
