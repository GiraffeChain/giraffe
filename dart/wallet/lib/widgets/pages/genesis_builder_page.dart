import '../../providers/genesis_builder.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' hide State;

class GenesisBuilderView extends ConsumerWidget {
  const GenesisBuilderView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(podGenesisBuilderProvider);
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
            onChanged: ref.read(podGenesisBuilderProvider.notifier).setSeed,
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
            onPressed: ref.read(podGenesisBuilderProvider.notifier).addStaker,
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
            onPressed: ref.read(podGenesisBuilderProvider.notifier).addUnstaked,
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
              .read(podGenesisBuilderProvider.notifier)
              .updateStakerQuantity(index, Int64.parseInt(value)),
        )),
        DataCell(TextFormField(
          initialValue: entry.$1.show,
          onChanged: (value) => ref
              .read(podGenesisBuilderProvider.notifier)
              .updateStakerAddress(index, decodeLockAddress(value)),
        )),
        DataCell(
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => ref
                .read(podGenesisBuilderProvider.notifier)
                .deleteStaker(index),
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
              .read(podGenesisBuilderProvider.notifier)
              .updateUnstakedQuantity(index, Int64.parseInt(value)),
        )),
        DataCell(TextFormField(
          initialValue: entry.$1.show,
          onChanged: (value) => ref
              .read(podGenesisBuilderProvider.notifier)
              .updateUnstakedAddress(index, decodeLockAddress(value)),
        )),
        DataCell(
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => ref
                .read(podGenesisBuilderProvider.notifier)
                .deleteUnstaked(index),
          ),
        ),
      ],
    );
  }

  Widget _saveButton(GenesisBuilderState state, WidgetRef ref) {
    final button = TextButton.icon(
      onPressed: ref.read(podGenesisBuilderProvider.notifier).save,
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
