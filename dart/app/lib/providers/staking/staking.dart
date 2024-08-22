import 'dart:convert';
import 'dart:math';

import 'package:blockchain_app/providers/blockchain_reader_writer.dart';
import 'package:blockchain_app/providers/storage.dart';
import 'package:blockchain_app/providers/wallet.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_protobuf/services/staker_support_rpc.pbgrpc.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:fixnum/fixnum.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../blockchain/codecs.dart';
import '../../blockchain/common/clock.dart';
import '../../blockchain/consensus/leader_election_validation.dart';
import '../../blockchain/minting/minting.dart';
import '../../blockchain/minting/models/staker_data.dart';
import '../../blockchain/minting/secure_store.dart';
import '../../blockchain/private_testnet.dart';
import '../../blockchain/staking_account.dart';
import 'staking_io.dart' if (dart.library.html) 'staking_web.dart'
    as staking_support;

part 'staking.freezed.dart';
part 'staking.g.dart';

@Riverpod(keepAlive: true)
class PodStaking extends _$PodStaking {
  @override
  PodStakingState build() => const PodStakingState(minting: null, stop: null);

  Future<void> initMinting() async {
    final readerWriter = ref.read(podBlockchainReaderWriterProvider);
    final viewer = readerWriter.view;
    final canonicalHeadId = await viewer.canonicalHeadId;
    final canonicalHead = await viewer.getBlockHeaderOrRaise(canonicalHeadId);
    log.info(
        "Canonical head id=${canonicalHeadId.show} height=${canonicalHead.height} slot=${canonicalHead.slot}");
    final protocolSettings = await viewer.protocolSettings;

    final genesisBlockId = await viewer.genesisBlockId;
    final genesisHeader = await viewer.getBlockHeaderOrRaise(genesisBlockId);
    log.info(
        "Genesis id=${genesisBlockId.show} height=${genesisHeader.height} slot=${genesisHeader.slot}");
    final stakerSupportClient = readerWriter.writer.stakerClient;
    final clock = ClockImpl(
      protocolSettings.slotDuration,
      protocolSettings.epochLength,
      protocolSettings.operationalPeriodLength,
      genesisHeader.timestamp,
    );
    final flutterSecureStorage = ref.read(podSecureStorageProvider);
    final secureStore = SecureStoreFromFunctions(
      writeKey: (value) => flutterSecureStorage.write(
          key: "blockchain-staker-kes", value: base64Encode(value)),
      readKey: () async => base64Decode(
          (await flutterSecureStorage.read(key: "blockchain-staker-kes"))!),
      eraseKey: () => flutterSecureStorage.delete(key: "blockchain-staker-kes"),
    );
    final stakerData = StakerData(
      vrfSk: base64Decode(
          (await flutterSecureStorage.read(key: "blockchain-staker-vrf-sk"))!),
      account: TransactionOutputReference.fromBuffer(base64Decode(
          (await flutterSecureStorage.read(
              key: "blockchain-staker-account"))!)),
      secureStore: secureStore,
      activationOperationalPeriod: Int64(0), // TODO
    );
    final leaderElection = LeaderElectionImpl(protocolSettings, isolate);
    final stakingAddress =
        (await ref.read(podWalletProvider.future)).defaultLockAddress;
    final mintingResource = Minting.makeForRpc(
      stakerData,
      protocolSettings,
      clock,
      canonicalHead,
      viewer.adoptions.map((id) {
        log.info("Remote peer adopted block id=${id.show}");
        return id;
      }).asyncMap(viewer.getBlockHeaderOrRaise),
      leaderElection,
      viewer,
      stakerSupportClient,
      stakingAddress,
    );
    final (f, dispose) = mintingResource
        .map(
          (m) => state = state.copyWith(minting: m),
        )
        .useForever()
        .unsafeRunFutureCancelable();
    f.ignore();
    ref.onDispose(dispose);
  }

  Future<void> initMintingTestnet(int index) async {
    final genesis =
        await ref.read(podBlockchainReaderWriterProvider).view.genesisBlock;
    final genesisTimestamp = genesis.header.timestamp;
    final seed = [...genesisTimestamp.immutableBytes, ...index.immutableBytes];
    final stakerInitializer = await StakingAccount.generate(
        ProtocolSettings.defaultSettings.kesTreeHeight,
        Int64(10000000),
        await PrivateTestnet.DefaultLockAddress,
        seed);
    final stakingAddress =
        StakingAddress(value: stakerInitializer.operatorVk.base58);
    final accountTx = genesis.fullBody.transactions.firstWhere((tx) => tx
        .outputs
        .where((o) =>
            o.value.hasAccountRegistration() &&
            o.value.accountRegistration.stakingRegistration.stakingAddress ==
                stakingAddress)
        .isNotEmpty);
    final account =
        TransactionOutputReference(transactionId: accountTx.id, index: 0);
    final secureStorage = ref.read(podSecureStorageProvider);
    await secureStorage.write(
        key: "blockchain-staker-vrf-sk",
        value: base64.encode(stakerInitializer.vrfSk));
    await secureStorage.write(
        key: "blockchain-staker-account",
        value: base64.encode(account.writeToBuffer()));
    await secureStorage.write(
        key: "blockchain-staker-kes",
        value: base64.encode(stakerInitializer.kesSk.encode));
    await initMinting();
  }

  Future<void> initMintingFromDirectory(
    String path,
  ) async {
    staking_support.initMintingFromDirectory(
        path, ref.read(podSecureStorageProvider));
    await initMinting();
  }

  Future<void> register() async {
    final wallet = await ref.read(podWalletProvider.future);
    final random = Random.secure();
    final seed = List.generate(32, (_) => random.nextInt(255));
    final readerWriter = ref.read(podBlockchainReaderWriterProvider);
    final stakerInitializer = await StakingAccount.generate(
      (await readerWriter.view.protocolSettings).kesTreeHeight,
      minimumStakeAccountQuantity,
      wallet.defaultLockAddress,
      seed,
    );
    final outputs = stakerInitializer.transaction.outputs;
    final inputs = <TransactionInput>[];
    var remaining = minimumStakeAccountQuantity;
    final availableInputKeys = wallet.spendableOutputs.keys.toList();
    final sortedInputs = wallet.spendableOutputs.entries
        .where((e) =>
            !e.value.value.hasGraphEntry() &&
            !e.value.value.hasAccountRegistration())
        .toList()
      ..sort((e1, e2) =>
          e1.value.value.quantity.compareTo(e2.value.value.quantity));

    if (sortedInputs.isEmpty) {
      throw Exception("No spendable funds");
    }
    var i = 0;
    while (remaining > Int64.ZERO && i < sortedInputs.length) {
      final key = availableInputKeys
          .removeAt(random.nextInt(availableInputKeys.length));
      final output = wallet.spendableOutputs[key]!;
      final value = output.value.quantity;
      inputs.add(TransactionInput(
        reference: key,
        value: output.value,
      ));
      remaining -= value;
      i++;
    }

    if (remaining > 0) {
      throw Exception("Not enough funds to register staking account");
    }

    if (remaining < 0) {
      outputs.add(TransactionOutput(
        lockAddress: wallet.defaultLockAddress,
        value: Value(quantity: -remaining),
      ));
    }
    final transaction = await wallet.attest(
        readerWriter.view,
        Transaction(
          inputs: inputs,
          outputs: outputs,
        ));
    await readerWriter.writer.submitTransaction(transaction);
    final account =
        TransactionOutputReference(transactionId: transaction.id, index: 0);
    final secureStorage = ref.read(podSecureStorageProvider);
    await secureStorage.write(
        key: "blockchain-staker-vrf-sk",
        value: base64.encode(stakerInitializer.vrfSk));
    await secureStorage.write(
        key: "blockchain-staker-account",
        value: base64.encode(account.writeToBuffer()));
    await secureStorage.write(
        key: "blockchain-staker-kes",
        value: base64.encode(stakerInitializer.kesSk.encode));
    await initMinting();
  }

  void start() {
    final minting = state.minting!;
    final readerWriter = ref.read(podBlockchainReaderWriterProvider);
    final subscription = minting.blockProducer.blocks
        .asyncMap((block) => readerWriter.writer.stakerClient
            .broadcastBlock(BroadcastBlockReq(
                block: Block(
                    header: block.header,
                    body: BlockBody(
                        transactionIds:
                            block.fullBody.transactions.map((t) => t.id)))))
            .then((_) => block))
        .listen(
          (block) => log.info(
              "Successfully broadcasted block id=${block.header.id.show}"),
          onError: (e, s) => log.severe("Production failed", e, s),
          onDone: () => log.info("Block production finished unexpectedly"),
        );
    ref.onDispose(subscription.cancel);
    state = state.copyWith(stop: () => subscription.cancel());
  }

  void stop() async {
    final f = state.stop?.call();
    state = state.copyWith(stop: null);
    await f;
  }

  void reset() async {
    final f = state.stop?.call();
    state = state.copyWith(minting: null, stop: null);
    await f;
    final flutterSecureStorage = ref.read(podSecureStorageProvider);
    await flutterSecureStorage.delete(key: "blockchain-staker-vrf-sk");
    await flutterSecureStorage.delete(key: "blockchain-staker-kes");
    await flutterSecureStorage.delete(key: "blockchain-staker-account");
  }

  static final log = Logger("Blockchain.Staking");
}

@freezed
class PodStakingState with _$PodStakingState {
  const factory PodStakingState(
      {required Minting? minting,
      required Future<void> Function()? stop}) = _PodStakingState;
}

final minimumStakeAccountQuantity = Int64(1000);
