import 'dart:convert';

import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/clock.dart';
import 'package:blockchain/consensus/leader_election_validation.dart';
import 'package:blockchain/minting/minting.dart';
import 'package:blockchain/minting/models/staker_data.dart';
import 'package:blockchain/minting/secure_store.dart';
import 'package:blockchain_app/providers/blockchain_reader_writer.dart';
import 'package:blockchain_app/providers/storage.dart';
import 'package:blockchain_app/providers/wallet.dart';
import 'package:blockchain_app/providers/wallet_key.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_protobuf/services/staker_support_rpc.pbgrpc.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:fixnum/fixnum.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'staking.freezed.dart';
part 'staking.g.dart';

@Riverpod(keepAlive: true)
class PodStaking extends _$PodStaking {
  @override
  PodStakingState build() => const PodStakingState(minting: null, stop: null);

  void initMinting() async {
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
    final dispose = mintingResource
        .map((m) => state = state.copyWith(minting: m))
        .useForever()
        .unsafeRunCancelable();
    ref.onDispose(dispose);
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
