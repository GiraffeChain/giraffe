import 'dart:convert';
import 'dart:io';

import 'package:blockchain_app/blockchain/private_testnet.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:fixnum/fixnum.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../blockchain/codecs.dart';
import '../blockchain/genesis.dart';
import '../blockchain/staking_account.dart';

part 'genesis_builder.freezed.dart';
part 'genesis_builder.g.dart';

@riverpod
class PodGenesisBuilder extends _$PodGenesisBuilder {
  @override
  GenesisBuilderState build() => GenesisBuilderState(
        seed: "test",
        stakers: List.empty(growable: true),
        unstaked: List.empty(growable: true),
        savedDir: null,
      );

  void setSeed(String seed) => state = state.copyWith(seed: seed);

  void addStaker() async {
    final stakers = state.stakers;
    state = state.copyWith(stakers: [
      ...stakers,
      (await PrivateTestnet.defaultLockAddress, Int64(10000))
    ]);
  }

  void updateStakerQuantity(int index, Int64 quantity) {
    final stakers = state.stakers;
    stakers[index] = (stakers[index].$1, quantity);
    state = state.copyWith(stakers: stakers);
  }

  void updateStakerAddress(int index, LockAddress address) {
    final stakers = state.stakers;
    stakers[index] = (address, stakers[index].$2);
    state = state.copyWith(stakers: stakers);
  }

  void deleteStaker(int index) {
    final stakers = state.stakers;
    stakers.removeAt(index);
    state = state.copyWith(stakers: stakers);
  }

  void addUnstaked() async {
    final unstaked = state.unstaked;
    state = state.copyWith(unstaked: [
      ...unstaked,
      (await PrivateTestnet.defaultLockAddress, Int64(10000))
    ]);
  }

  void updateUnstakedQuantity(int index, Int64 quantity) {
    final unstaked = state.unstaked;
    unstaked[index] = (unstaked[index].$1, quantity);
    state = state.copyWith(unstaked: unstaked);
  }

  void updateUnstakedAddress(int index, LockAddress address) {
    final unstaked = state.unstaked;
    unstaked[index] = (address, unstaked[index].$2);
    state = state.copyWith(unstaked: unstaked);
  }

  void deleteUnstaked(int index) {
    final unstaked = state.unstaked;
    unstaked.removeAt(index);
    state = state.copyWith(unstaked: unstaked);
  }

  Future<void> save() async {
    final genesisInitDirectory = Directory(
        "${(await getApplicationDocumentsDirectory()).path}/blockchain/genesis-init");
    final stakers = await Future.wait(state.stakers.mapWithIndex((e, index) {
      final seed = utf8.encode(state.seed + index.toString());
      return StakingAccount.generate(e.$2, e.$1, seed);
    }).toList());
    final unstakedTransaction = Transaction(
        outputs: state.unstaked.map((t) => TransactionOutput(
            lockAddress: t.$1, value: Value(quantity: t.$2))));
    final genesisTransactions = [
      unstakedTransaction,
      ...stakers.map((s) => s.transaction)
    ];
    final genesisConfig = GenesisConfig(
        Int64(DateTime.now().millisecondsSinceEpoch),
        genesisTransactions,
        [],
        ProtocolSettings.defaultAsMap);
    final genesis = genesisConfig.block;

    final saveDir =
        Directory("${genesisInitDirectory.path}/${genesis.header.id.show}");
    await Future.wait(stakers.mapWithIndex(
        (s, index) => s.save(Directory("${saveDir.path}/stakers/$index"))));
    await Genesis.save(saveDir, genesis);
    state = state.copyWith(savedDir: saveDir);
  }
}

@Freezed(makeCollectionsUnmodifiable: false)
class GenesisBuilderState with _$GenesisBuilderState {
  const factory GenesisBuilderState({
    required String seed,
    required List<(LockAddress, Int64)> stakers,
    required List<(LockAddress, Int64)> unstaked,
    required Directory? savedDir,
  }) = _GenesisBuilderState;
}
