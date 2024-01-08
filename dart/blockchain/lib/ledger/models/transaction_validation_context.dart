import 'package:blockchain/codecs.dart';
import 'package:blockchain/crypto/ed25519.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';

class TransactionValidationContext {
  final BlockId parentHeaderId;
  final Int64 height;
  final Int64 slot;

  TransactionValidationContext(
    this.parentHeaderId,
    this.height,
    this.slot,
  );
}

class WitnessContext {
  final Int64 height;
  final Int64 slot;
  final List<int> messageToSign;

  WitnessContext(
      {required this.height, required this.slot, required this.messageToSign});

  Future<List<String>> validate(Witness witness) async {
    final expectedAddress = witness.lock.address;
    if (witness.lockAddress != expectedAddress) return ["Invalid LockAddress"];

    if (witness.lock.hasEd25519() && witness.key.hasEd25519()) {
      final isValid = await ed25519.verify(witness.key.ed25519.signature,
          messageToSign, witness.lock.ed25519.vk);
      if (isValid)
        return [];
      else
        return ["Signature mismatch"];
    }
    return ["Invalid Lock/Key type"];
  }
}
