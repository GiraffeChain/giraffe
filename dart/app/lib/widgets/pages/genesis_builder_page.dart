import 'dart:convert';
import 'dart:io';

import 'package:blockchain/codecs.dart';
import 'package:blockchain/staking_account.dart';
import 'package:blockchain/consensus/models/protocol_settings.dart';
import 'package:blockchain/crypto/impl/kes_product.dart';
import 'package:blockchain/genesis.dart';
import 'package:blockchain/private_testnet.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'genesis_builder_page.freezed.dart';
part 'genesis_builder_page.g.dart';

@riverpod
class GenesisBuilder extends _$GenesisBuilder {
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
      (await PrivateTestnet.DefaultLockAddress, Int64(10000))
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
      (await PrivateTestnet.DefaultLockAddress, Int64(10000))
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
    final kesTreeHeight = TreeHeight(
        ProtocolSettings.defaultSettings.kesKeyHours,
        ProtocolSettings.defaultSettings.kesKeyMinutes);
    final stakers = await Future.wait(state.stakers.mapWithIndex((e, index) {
      final seed = utf8.encode(state.seed + index.toString());
      return StakingAccount.generate(kesTreeHeight, e.$2, e.$1, seed);
    }).toList());
    final genesisTransactions = stakers.map((s) => s.transaction).toList();
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
    await Genesis.save(Directory("${saveDir.path}/genesis"), genesis);
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

class GenesisBuilderView extends ConsumerWidget {
  const GenesisBuilderView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(genesisBuilderProvider);
    return SingleChildScrollView(
      child: Center(
        child: SizedBox(
          width: 800,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Genesis Builder",
                    style: TextStyle(fontSize: 44, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _seedRow(state, ref),
                  const Divider(),
                  _formRow("Stakers", _stakersTile(state, ref)),
                  const Divider(),
                  _formRow("Unstaked", _unstakedTile(state, ref)),
                  const Divider(),
                  _saveButton(state, ref),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _seedRow(GenesisBuilderState state, WidgetRef ref) {
    return _formRow(
        "Seed",
        SizedBox(
          width: 150,
          child: TextField(
            controller: TextEditingController(text: state.seed),
            onChanged: ref.read(genesisBuilderProvider.notifier).setSeed,
          ),
        ));
  }

  Widget _formRow(String header, Widget body) =>
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            header,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        body
      ]);

  Widget _stakersTile(GenesisBuilderState state, WidgetRef ref) {
    return Column(
      children: [
        DataTable(
          columns: _tableHeader,
          rows: state.stakers
              .mapWithIndex((e, i) => _stakerEntryRow(ref, e, i))
              .toList(),
        ),
        IconButton(
            onPressed: ref.read(genesisBuilderProvider.notifier).addStaker,
            icon: const Icon(Icons.add))
      ],
    );
  }

  Widget _unstakedTile(GenesisBuilderState state, WidgetRef ref) {
    return Column(
      children: [
        DataTable(
          columns: _tableHeader,
          rows: state.unstaked
              .mapWithIndex((e, i) => _unstakedEntryRow(ref, e, i))
              .toList(),
        ),
        IconButton(
            onPressed: ref.read(genesisBuilderProvider.notifier).addUnstaked,
            icon: const Icon(Icons.add))
      ],
    );
  }

  static const _tableHeader = <DataColumn>[
    DataColumn(
      label: Expanded(
        child: Text(
          'Quantity',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
    ),
    DataColumn(
      label: Expanded(
        child: Text(
          'Lock Address',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
    ),
    DataColumn(
      label: Expanded(
        child: Text(
          'Remove',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
    ),
  ];

  DataRow _stakerEntryRow(
      WidgetRef ref, (LockAddress, Int64) entry, int index) {
    return DataRow(
      cells: [
        DataCell(TextFormField(
          initialValue: entry.$2.toString(),
          onChanged: (value) => ref
              .read(genesisBuilderProvider.notifier)
              .updateStakerQuantity(index, Int64.parseInt(value)),
        )),
        DataCell(TextFormField(
          initialValue: entry.$1.show,
          onChanged: (value) => ref
              .read(genesisBuilderProvider.notifier)
              .updateStakerAddress(index, decodeLockAddress(value)),
        )),
        DataCell(
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () =>
                ref.read(genesisBuilderProvider.notifier).deleteStaker(index),
          ),
        ),
      ],
    );
  }

  DataRow _unstakedEntryRow(
      WidgetRef ref, (LockAddress, Int64) entry, int index) {
    return DataRow(
      cells: [
        DataCell(TextFormField(
          initialValue: entry.$2.toString(),
          onChanged: (value) => ref
              .read(genesisBuilderProvider.notifier)
              .updateUnstakedQuantity(index, Int64.parseInt(value)),
        )),
        DataCell(TextFormField(
          initialValue: entry.$1.show,
          onChanged: (value) => ref
              .read(genesisBuilderProvider.notifier)
              .updateUnstakedAddress(index, decodeLockAddress(value)),
        )),
        DataCell(
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () =>
                ref.read(genesisBuilderProvider.notifier).deleteUnstaked(index),
          ),
        ),
      ],
    );
  }

  Widget _saveButton(GenesisBuilderState state, WidgetRef ref) {
    final button = TextButton.icon(
      onPressed: ref.read(genesisBuilderProvider.notifier).save,
      icon: const Icon(Icons.save),
      label: const Text("Save"),
    );
    return state.savedDir == null
        ? button
        : Row(
            children: [
              button,
              Text("Saved to ${state.savedDir!.path}"),
            ],
          );
  }
}
