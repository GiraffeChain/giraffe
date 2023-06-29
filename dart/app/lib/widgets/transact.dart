import 'dart:async';
import 'dart:convert';

import 'package:blockchain_codecs/codecs.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_wallet/wallet.dart';
import 'package:fast_base58/fast_base58.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show FpdartOnMutableIterable, Tuple2;
import 'package:flutter/services.dart';

class TransactView extends StatefulWidget {
  final Wallet wallet;
  final Future<void> Function(Transaction) processTransaction;

  const TransactView(
      {super.key, required this.wallet, required this.processTransaction});
  @override
  State<StatefulWidget> createState() => TransactViewState();
}

class TransactViewState extends State<TransactView> {
  Set<TransactionOutputReference> _selectedInputs = {};
  List<Tuple2<String, String>> _newOutputEntries = [];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(80),
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
                      body: TransactInputsTile(
                        spendableOutputs: widget.wallet.spendableOutputs,
                        onSelectionChanged: (entries) =>
                            _selectedInputs = entries,
                      )),
                  ExpansionPanelRadio(
                      value: "Outputs",
                      headerBuilder: (context, isExpanded) =>
                          const ListTile(title: Text("Outputs")),
                      body: TransactOutputsTile(
                          onEntriesChanged: (entries) =>
                              _newOutputEntries = entries)),
                ]),
              ),
            ),
            IconButton(
              onPressed: _transact,
              icon: const Icon(Icons.send),
            )
          ],
        ),
      ),
    );
  }

  Future<Transaction> _createTransaction() async {
    var tx = Transaction();

    for (final ref in _selectedInputs) {
      final output = widget.wallet.spendableOutputs[ref]!;
      final lock = widget.wallet.locks[output.lockAddress]!;
      final input = TransactionInput()
        ..value = output.value
        ..reference = ref
        ..lock = lock;
      tx.inputs.add(input);
    }

    for (final e in _newOutputEntries) {
      final lockAddress = LockAddress()..value = Base58Decode(e.second);
      final value = Value()
        ..paymentToken = (PaymentToken()..quantity = Int64.parseInt(e.first));
      final output = TransactionOutput()
        ..lockAddress = lockAddress
        ..value = value;
      tx.outputs.add(output);
    }

    final schedule = TransactionSchedule()
      ..maxSlot = Int64.MAX_VALUE
      ..timestamp = Int64(DateTime.now().millisecondsSinceEpoch);

    tx.schedule = schedule;

    for (final ref in _selectedInputs.toList()) {
      final output = widget.wallet.spendableOutputs[ref]!;
      final signer = widget.wallet.signers[output.lockAddress]!;
      tx = await signer(tx);
    }

    return tx;
  }

  _transact() async {
    final tx = await _createTransaction();
    await widget.processTransaction(tx);
    setState(() {
      _selectedInputs = {};
      _newOutputEntries = [];
    });
  }
}

class TransactOutputsTile extends StatefulWidget {
  final void Function(List<Tuple2<String, String>>) onEntriesChanged;

  TransactOutputsTile({super.key, required this.onEntriesChanged});

  @override
  State<TransactOutputsTile> createState() => _TransactOutputsTileState();
}

class _TransactOutputsTileState extends State<TransactOutputsTile> {
  // (quantity, address)
  final List<Tuple2<String, String>> _entries = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DataTable(
          columns: header,
          rows: _entries.mapWithIndex(_entryRow).toList(),
        ),
        IconButton(onPressed: _addEntry, icon: const Icon(Icons.add))
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
          'Remove',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
    ),
  ];

  DataRow _entryRow(Tuple2<String, String> entry, int index) {
    return DataRow(
      cells: [
        DataCell(TextFormField(
          initialValue: entry.first,
          onChanged: (value) => _updateEntryQuantity(index, value ?? ""),
        )),
        DataCell(TextFormField(
          initialValue: entry.second,
          onChanged: (value) => _updateEntryAddress(index, value ?? ""),
        )),
        DataCell(
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteEntry(index),
          ),
        ),
      ],
    );
  }

  _updateEntryQuantity(int index, String value) {
    setState(() {
      _entries[index] = _entries[index].copyWith(value1: value);
      widget.onEntriesChanged(_entries);
    });
  }

  _updateEntryAddress(int index, String value) {
    setState(() {
      _entries[index] = _entries[index].copyWith(value2: value);
      widget.onEntriesChanged(_entries);
    });
  }

  _addEntry() {
    setState(() {
      _entries.add(const Tuple2("100", ""));
      widget.onEntriesChanged(_entries);
    });
  }

  _deleteEntry(int index) {
    setState(() {
      _entries.removeAt(index);
      widget.onEntriesChanged(_entries);
    });
  }
}

class TransactInputsTile extends StatefulWidget {
  final Map<TransactionOutputReference, TransactionOutput> spendableOutputs;
  final void Function(Set<TransactionOutputReference>) onSelectionChanged;
  const TransactInputsTile({
    super.key,
    required this.spendableOutputs,
    required this.onSelectionChanged,
  });

  @override
  State<TransactInputsTile> createState() => _TransactInputsTileState();
}

class _TransactInputsTileState extends State<TransactInputsTile> {
  final _selectedOutputs = <TransactionOutputReference>{};
  @override
  Widget build(BuildContext context) {
    return Container(
        child: widget.spendableOutputs.isEmpty
            ? const Text("Empty wallet")
            : DataTable(
                columns: header,
                rows: widget.spendableOutputs.entries.map(entryRow).toList(),
              ));
  }

  DataRow entryRow(
      MapEntry<TransactionOutputReference, TransactionOutput> entry) {
    return DataRow(
      cells: [
        DataCell(Text("${entry.value.value.paymentToken.quantity}",
            style: const TextStyle(fontSize: 12))),
        DataCell(TextButton(
          onPressed: () {
            Clipboard.setData(
                ClipboardData(text: entry.value.lockAddress.show));
          },
          child: Text(entry.value.lockAddress.show,
              style: const TextStyle(fontSize: 12)),
        )),
        DataCell(Checkbox(
            value: _selectedOutputs.contains(entry.key),
            onChanged: (newValue) =>
                _updateEntry(entry.key, newValue ?? false))),
      ],
    );
  }

  _updateEntry(TransactionOutputReference ref, bool retain) {
    setState(() {
      if (retain) {
        _selectedOutputs.add(ref);
      } else {
        _selectedOutputs.remove(ref);
      }
      widget.onSelectionChanged(_selectedOutputs);
    });
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
