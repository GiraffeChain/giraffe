import 'dart:typed_data';

import 'package:blockchain/crypto/impl/ec.dart' as ec;
import 'package:blockchain/crypto/utils.dart';
import 'package:cryptography/cryptography.dart' as c;

abstract class Ed25519 {
  Future<Ed25519KeyPair> generateKeyPair();
  Future<Ed25519KeyPair> generateKeyPairFromSeed(List<int> seed);
  Future<List<int>> sign(List<int> message, List<int> sk);
  Future<List<int>> signKeyPair(List<int> message, Ed25519KeyPair keyPair);
  Future<bool> verify(List<int> signature, List<int> message, List<int> vk);
  Future<List<int>> getVerificationKey(List<int> sk);
}

Ed25519 ed25519 = Ed25519Impl();

class Ed25519KeyPair {
  final List<int> sk;
  final List<int> vk;

  Ed25519KeyPair(this.sk, this.vk);
}

class Ed25519Impl extends Ed25519 {
  @override
  Future<Ed25519KeyPair> generateKeyPair() => _generateKeyPair();

  @override
  Future<Ed25519KeyPair> generateKeyPairFromSeed(List<int> seed) =>
      _generateKeyPairFromSeed(seed);

  @override
  Future<List<int>> getVerificationKey(List<int> sk) => _getVerificationKey(sk);

  @override
  Future<List<int>> sign(List<int> message, List<int> sk) => _sign(message, sk);

  @override
  Future<List<int>> signKeyPair(List<int> message, Ed25519KeyPair keyPair) =>
      _signKeyPair(message, keyPair);

  @override
  Future<bool> verify(List<int> signature, List<int> message, List<int> vk) =>
      _verify(signature, message, vk);
}

class Ed25519Isolated extends Ed25519 {
  final DComputeImpl _compute;

  Ed25519Isolated(this._compute);

  @override
  Future<Ed25519KeyPair> generateKeyPair() async =>
      _compute((v) => _generateKeyPair(), {});

  @override
  Future<Ed25519KeyPair> generateKeyPairFromSeed(List<int> seed) async =>
      _compute(_generateKeyPairFromSeed, seed);

  @override
  Future<List<int>> getVerificationKey(List<int> sk) async =>
      _compute(_getVerificationKey, sk);

  @override
  Future<List<int>> sign(List<int> message, List<int> sk) async =>
      _compute((t) => _sign(t.$1, t.$2), (message, sk));

  @override
  Future<List<int>> signKeyPair(
          List<int> message, Ed25519KeyPair keyPair) async =>
      _compute((t) => _signKeyPair(t.$1, t.$2), (message, keyPair));

  @override
  Future<bool> verify(
          List<int> signature, List<int> message, List<int> vk) async =>
      _compute(
          (t) => _verify(t.$1.$1, t.$1.$2, t.$2), ((signature, message), vk));
}

final _algorithm = c.Ed25519();

Future<Ed25519KeyPair> _convertAlgKeypair(c.SimpleKeyPair algKeypair) async {
  final sk = await algKeypair.extractPrivateKeyBytes();
  final vk = await algKeypair.extractPublicKey();
  final uint8Vk = Uint8List.fromList(vk.bytes);
  return Ed25519KeyPair(Uint8List.fromList(sk), uint8Vk);
}

Future<Ed25519KeyPair> _generateKeyPair() async {
  return _convertAlgKeypair(await _algorithm.newKeyPair());
}

Future<Ed25519KeyPair> _generateKeyPairFromSeed(List<int> seed) async {
  return _convertAlgKeypair(await _algorithm.newKeyPairFromSeed(seed));
}

Future<List<int>> _sign(List<int> message, List<int> sk) async {
  final vk = await _getVerificationKey(sk);
  final uintRes = await _signKeyPair(message, Ed25519KeyPair(sk, vk));
  return Uint8List.fromList(uintRes);
}

Future<List<int>> _signKeyPair(
    List<int> message, Ed25519KeyPair keyPair) async {
  final algKeyPair = c.SimpleKeyPairData(
    keyPair.sk,
    publicKey: c.SimplePublicKey(keyPair.vk, type: c.KeyPairType.ed25519),
    type: c.KeyPairType.ed25519,
  );

  final algSignature = await _algorithm.sign(message, keyPair: algKeyPair);

  return algSignature.bytes;
}

Future<bool> _verify(
    List<int> signature, List<int> message, List<int> vk) async {
  final _sig = Uint8List.fromList(signature);
  final _message = Uint8List.fromList(message);
  final _vk = Uint8List.fromList(vk);
  final result = await _algorithm.verify(
    _message,
    signature: c.Signature(
      _sig,
      publicKey: c.SimplePublicKey(_vk, type: c.KeyPairType.ed25519),
    ),
  );
  return result;
}

Future<List<int>> _getVerificationKey(List<int> sk) async {
  final h = Uint8List.fromList((await c.Sha512().hash(sk)).bytes)
      .int8List
      .sublist(0, 32);
  final s = Int8List(ec.SCALAR_BYTES);
  ec.pruneScalar(h, 0, s);
  final vk = Int8List(32);
  ec.scalarMultBaseEncoded(s, vk, 0);
  return Uint8List.fromList(vk);
}
