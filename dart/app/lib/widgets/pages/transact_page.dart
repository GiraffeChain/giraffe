import 'dart:async';

import 'package:blockchain_app/providers/transact.dart';
import 'package:blockchain_app/providers/wallet.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:fpdart/fpdart.dart' hide State;

class StreamedTransactView extends ConsumerWidget {
  final BlockchainClient client;

  const StreamedTransactView({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(podWalletProvider)) {
      AsyncData(:final value) => TransactView(
          wallet: value,
          client: client,
        ),
      AsyncError(:final error) =>
        Center(child: Text("An error occurred: $error")),
      _ => const Center(child: CircularProgressIndicator())
    };
  }
}

class TransactView extends ConsumerWidget {
  TransactView({
    super.key,
    required this.wallet,
    required this.client,
  });

  final Wallet wallet;
  final BlockchainClient client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(podTransactProvider);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Card(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: ExpansionPanelList.radio(children: [
                  ExpansionPanelRadio(
                    value: "Inputs",
                    headerBuilder: (context, isExpanded) =>
                        const ListTile(title: Text("Inputs")),
                    body: _inputsTile(ref, state),
                  ),
                  ExpansionPanelRadio(
                      value: "Outputs",
                      headerBuilder: (context, isExpanded) =>
                          const ListTile(title: Text("Outputs")),
                      body: _outputsTile(ref, state)),
                ]),
              ),
            ),
            IconButton(
              onPressed: () => _transact(ref, state),
              icon: const Icon(Icons.send),
            )
          ],
        ),
      ),
    );
  }

  Int64 _inputSum(WidgetRef ref, TransactState state) => state.selectedInputs
      .toList()
      .map((v) => wallet.spendableOutputs[v]!.value)
      .map((v) => v.quantity)
      .fold(Int64.ZERO, (a, b) => a + b);

  Future<Transaction> _createTransaction(
      WidgetRef ref, TransactState state) async {
    var tx = Transaction();

    for (final ref in state.selectedInputs) {
      final output = wallet.spendableOutputs[ref]!;
      final input = TransactionInput()
        ..value = output.value
        ..reference = ref;
      tx.inputs.add(input);
    }

    for (final e in state.newOutputEntries) {
      final lockAddress = decodeLockAddress(e.$2);
      final value = Value()..quantity = Int64.parseInt(e.$1);
      final output = TransactionOutput()
        ..lockAddress = lockAddress
        ..value = value;
      tx.outputs.add(output);
    }
    final head = await client.canonicalHead;
    final witnessContext = WitnessContext(
      height: head.height + 1,
      messageToSign: tx.signableBytes,
    );
    for (final lockAddress
        in await tx.requiredWitnesses(client.getTransactionOutputOrRaise)) {
      final signer = wallet.signers[lockAddress]!;
      final witness = await signer(witnessContext);
      tx.attestation.add(witness);
    }

    return tx;
  }

  final log = Logger("Transact");

  _transact(WidgetRef ref, TransactState state) async {
    final tx = await _createTransaction(ref, state);
    log.info("Broadcasting transaction id=${tx.id.show}");
    await client.broadcastTransaction(tx);
    ref.read(podTransactProvider.notifier).reset();
  }

  Widget _outputsTile(WidgetRef ref, TransactState state) {
    return Column(
      children: [
        DataTable(
          columns: _outputTableHeader,
          rows: [
            ...state.newOutputEntries
                .mapWithIndex((v, i) => _outputEntryRow(v, i, ref, state)),
            _feeOutputRow(ref, state)
          ],
        ),
        IconButton(
            onPressed: () => ref.read(podTransactProvider.notifier).addOutput(),
            icon: const Icon(Icons.add))
      ],
    );
  }

  static const _outputTableHeader = <DataColumn>[
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

  DataRow _outputEntryRow(
      (String, String) entry, int index, WidgetRef ref, TransactState state) {
    return DataRow(
      cells: [
        DataCell(TextFormField(
          initialValue: entry.$1,
          onChanged: (value) => ref
              .read(podTransactProvider.notifier)
              .updateOutput(index, value, state.newOutputEntries[index].$2),
        )),
        DataCell(TextFormField(
          initialValue: entry.$2,
          onChanged: (value) => ref
              .read(podTransactProvider.notifier)
              .updateOutput(index, state.newOutputEntries[index].$1, value),
        )),
        DataCell(
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () =>
                ref.read(podTransactProvider.notifier).removeOutput(index),
          ),
        ),
      ],
    );
  }

  DataRow _feeOutputRow(WidgetRef ref, TransactState state) {
    Int64 outputSum = Int64.ZERO;
    String? errorText;
    for (final t in state.newOutputEntries) {
      final parsed = Int64.tryParseInt(t.$1);
      if (parsed == null) {
        errorText = "?";
        break;
      } else {
        outputSum += parsed;
      }
    }

    return DataRow(cells: [
      DataCell(
          Text(errorText ?? (_inputSum(ref, state) - outputSum).toString())),
      const DataCell(Text("Tip")),
      const DataCell(IconButton(
        icon: Icon(Icons.cancel),
        onPressed: null,
      )),
    ]);
  }

  Widget _inputsTile(WidgetRef ref, TransactState state) {
    return Container(
        child: wallet.spendableOutputs.isEmpty
            ? const Text("Empty wallet")
            : DataTable(
                columns: header,
                rows: wallet.spendableOutputs.entries
                    // Hide registrations for now
                    .where((e) => !e.value.value.hasAccountRegistration())
                    .map((entry) => _inputEntryRow(entry, ref, state))
                    .toList(),
              ));
  }

  DataRow _inputEntryRow(
      MapEntry<TransactionOutputReference, TransactionOutput> entry,
      WidgetRef ref,
      TransactState state) {
    return DataRow(
      cells: [
        DataCell(Text("${entry.value.value.quantity}",
            style: const TextStyle(fontSize: 12))),
        DataCell(TextButton(
          onPressed: () {
            Clipboard.setData(
                ClipboardData(text: entry.value.lockAddress.show));
          },
          child: Text(entry.value.lockAddress.show,
              style: const TextStyle(fontSize: 12)),
        )),
        DataCell(
          Checkbox(
            value: state.selectedInputs.contains(entry.key),
            onChanged: (newValue) => newValue ?? false
                ? ref.read(podTransactProvider.notifier).selectInput(entry.key)
                : ref
                    .read(podTransactProvider.notifier)
                    .unselectInput(entry.key),
          ),
        ),
      ],
    );
  }

  static const header = <DataColumn>[
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
          'Selected',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
    ),
  ];
}
