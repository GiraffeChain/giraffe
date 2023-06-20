import 'package:blockchain_codecs/codecs.dart';
import 'package:blockchain_crypto/ed25519.dart';
import 'package:blockchain_crypto/ed25519vrf.dart';
import 'package:blockchain_crypto/kes.dart';
import 'package:blockchain_crypto/utils.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';

class StakerInitializer {
  final Ed25519KeyPair operatorKeyPair;
  final Ed25519KeyPair walletKeyPair;
  final Ed25519KeyPair spendingKeyPair;
  final Ed25519VRFKeyPair vrfKeyPair;
  final KeyPairKesProduct kesKeyPair;

  StakerInitializer(this.operatorKeyPair, this.walletKeyPair,
      this.spendingKeyPair, this.vrfKeyPair, this.kesKeyPair);

  static Future<StakerInitializer> fromSeed(
      List<int> seed, TreeHeight treeHeight) async {
    final operatorKeyPair =
        await ed25519.generateKeyPairFromSeed(await (seed + [1]).hash256);
    final walletKeyPair =
        await ed25519.generateKeyPairFromSeed(await (seed + [2]).hash256);
    final spendingKeyPair =
        await ed25519.generateKeyPairFromSeed(await (seed + [3]).hash256);
    final vrfKeyPair =
        await ed25519Vrf.generateKeyPairFromSeed(await (seed + [4]).hash256);
    final kesKeyPair = await kesProduct.generateKeyPair(
        await (seed + [5]).hash256, treeHeight, Int64.ZERO);

    return StakerInitializer(
      operatorKeyPair,
      walletKeyPair,
      spendingKeyPair,
      vrfKeyPair,
      kesKeyPair,
    );
  }

  Future<SignatureKesProduct> get registration async => kesProduct.sign(
        kesKeyPair.sk,
        await (vrfKeyPair.vk + operatorKeyPair.vk).hash256,
      );

  StakingAddress get stakingAddress =>
      StakingAddress()..value = operatorKeyPair.vk;

  Lock get spendingLock =>
      Lock()..ed25519 = (Lock_Ed25519()..vk = spendingKeyPair.vk);

  LockAddress get lockAddress => spendingLock.address;

  Future<List<TransactionOutput>> genesisOutputs(Int64 stake) async {
    final spendingValue = Value()
      ..paymentToken = (PaymentToken()..quantity = stake);
    final registrationValue = Value()
      ..stakingToken = (StakingToken()
        ..quantity = stake
        ..registration = (StakingRegistration()
          ..signature = await registration
          ..stakingAddress = stakingAddress));
    return [
      TransactionOutput()
        ..lockAddress = lockAddress
        ..value = spendingValue,
      TransactionOutput()
        ..lockAddress = lockAddress
        ..value = registrationValue
    ];
  }
}
