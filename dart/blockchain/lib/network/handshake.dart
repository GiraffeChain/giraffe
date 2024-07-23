import 'dart:math';
import 'dart:typed_data';

import 'package:blockchain_sdk/sdk.dart';
import 'package:blockchain/network/util.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

class HandshakeResult {
  final PeerId peerId;

  HandshakeResult(this.peerId);
}

final _timeout = Duration(seconds: 2);

Future<HandshakeResult> handshake(BytesReader reader, BytesWriter writer,
    Ed25519KeyPair localPeerKey, Uint8List magicBytes) async {
  await writer(magicBytes).timeout(_timeout);
  final remoteMagicBytes = await reader(32).timeout(_timeout);
  if (!magicBytes.sameElements(Uint8List.fromList(remoteMagicBytes)))
    throw new ArgumentError("Invalid remote magic bytes");
  await writer(localPeerKey.vk).timeout(_timeout);
  final remoteVk = await reader(32).timeout(_timeout);
  final localChallenge = List.generate(32, (i) => Random().nextInt(256));
  await writer(localChallenge).timeout(_timeout);
  final remoteChallenge = await reader(32).timeout(_timeout);
  final localSignature = await ed25519.sign(remoteChallenge, localPeerKey.sk);
  await writer(localSignature).timeout(_timeout);
  final remoteSignature = await reader(64).timeout(_timeout);
  if (!(await ed25519.verify(remoteSignature, localChallenge, remoteVk)))
    throw ArgumentError("Invalid remote signature");
  final peerId = PeerId(value: remoteVk.base58);
  return HandshakeResult(peerId);
}
