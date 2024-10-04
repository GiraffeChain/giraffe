import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:fast_base58/fast_base58.dart';
import 'package:giraffe_sdk/sdk.dart';

class Handshaker {
  final Uint8List magicBytes;
  final Uint8List sk;
  final Uint8List vk;

  Handshaker({required this.magicBytes, required this.sk, required this.vk});

  static final _random = SecureRandom.fast;

  Future<PeerId> shakeHands(Future<Uint8List> Function(int) read,
      void Function(Uint8List) write) async {
    write(magicBytes);
    final peerMagicBytes = await read(magicBytes.length);
    assert(peerMagicBytes.sameElements(magicBytes), "Invalid magic bytes");
    write(vk);
    final peerVk = await read(vk.length);
    final localChallenge = _createLocalChallenge;
    write(localChallenge);
    final remoteChallenge = await read(localChallenge.length);
    final localSignature = await ed25519.sign(remoteChallenge, sk);
    write(localSignature);
    final remoteSignature = await read(localSignature.length);
    assert(await ed25519.verify(remoteSignature, localChallenge, peerVk),
        "Invalid remote signature");
    return PeerId(value: Base58Encode(peerVk));
  }

  Uint8List get _createLocalChallenge =>
      Uint8List.fromList(List.generate(32, (index) => _random.nextInt(256)));
}
