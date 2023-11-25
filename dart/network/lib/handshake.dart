import 'dart:math';
import 'dart:typed_data';

import 'package:blockchain_crypto/ed25519.dart';
import 'package:blockchain_crypto/utils.dart';
import 'package:blockchain_network/util.dart';

class HandshakeResult {
  final PeerId peerId;

  HandshakeResult(this.peerId);
}

Future<HandshakeResult> handshake(BytesReader reader, BytesWriter writer,
    Ed25519KeyPair localPeerKey, Uint8List magicBytes) async {
  await writer(magicBytes);
  final remoteMagicBytes = await reader(32);
  if (!magicBytes.sameElements(Uint8List.fromList(remoteMagicBytes)))
    throw new ArgumentError("Invalid remote magic bytes");
  await writer(localPeerKey.vk);
  final remoteVk = await reader(32);
  final localChallenge = List.generate(32, (i) => Random().nextInt(256));
  await writer(localChallenge);
  final remoteChallenge = await reader(32);
  final localSignature = await ed25519.sign(remoteChallenge, localPeerKey.sk);
  await writer(localSignature);
  final remoteSignature = await reader(32);
  if (!(await ed25519.verify(remoteSignature, localChallenge, remoteVk)))
    throw ArgumentError("Invalid remote signature");
  final peerId = Uint8List.fromList(remoteVk);
  return HandshakeResult(peerId);
}
