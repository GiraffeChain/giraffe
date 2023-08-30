import 'dart:async';

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
                    body: _inputsTile(),
                  ),
                  ExpansionPanelRadio(
                      value: "Outputs",
                      headerBuilder: (context, isExpanded) =>
                          const ListTile(title: Text("Outputs")),
                      body: _outputsTile()),
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

  Int64 _inputSum() => _selectedInputs
      .toList()
      .map((v) => widget.wallet.spendableOutputs[v]!.value)
      .where((v) => v.hasPaymentToken())
      .map((v) => v.paymentToken.quantity)
      .fold(Int64.ZERO, (a, b) => a + b);

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

  Widget _outputsTile() {
    return Column(
      children: [
        DataTable(
          columns: _outputTableHeader,
          rows: [
            ..._newOutputEntries.mapWithIndex(_outputEntryRow).toList(),
            _feeOutputRow()
          ],
        ),
        IconButton(onPressed: _addOutputEntry, icon: const Icon(Icons.add))
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

  DataRow _outputEntryRow(Tuple2<String, String> entry, int index) {
    return DataRow(
      cells: [
        DataCell(TextFormField(
          initialValue: entry.first,
          onChanged: (value) => _updateOutputEntryQuantity(index, value),
        )),
        DataCell(TextFormField(
          initialValue: entry.second,
          onChanged: (value) => _updateOutputEntryAddress(index, value),
        )),
        DataCell(
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteOutputEntry(index),
          ),
        ),
      ],
    );
  }

  DataRow _feeOutputRow() {
    final outputSum = _newOutputEntries
        .map((t) => Int64.parseInt(t.first))
        .fold(Int64.ZERO, (a, b) => a + b);
    final fee = _inputSum() - outputSum;

    return DataRow(cells: [
      DataCell(Text(fee.toString())),
      const DataCell(Text("Transaction Fee")),
      const DataCell(IconButton(
        icon: Icon(Icons.cancel),
        onPressed: null,
      )),
    ]);
  }

  _updateOutputEntryQuantity(int index, String value) {
    setState(() {
      _newOutputEntries[index] =
          _newOutputEntries[index].copyWith(value1: value);
    });
  }

  _updateOutputEntryAddress(int index, String value) {
    setState(() {
      _newOutputEntries[index] =
          _newOutputEntries[index].copyWith(value2: value);
    });
  }

  _addOutputEntry() {
    setState(() {
      _newOutputEntries.add(const Tuple2("100", ""));
    });
  }

  _deleteOutputEntry(int index) {
    setState(() {
      _newOutputEntries.removeAt(index);
    });
  }

  Widget _inputsTile() {
    return Container(
        child: widget.wallet.spendableOutputs.isEmpty
            ? const Text("Empty wallet")
            : DataTable(
                columns: header,
                rows: widget.wallet.spendableOutputs.entries
                    .map(_inputEntryRow)
                    .toList(),
              ));
  }

  DataRow _inputEntryRow(
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
            value: _selectedInputs.contains(entry.key),
            onChanged: (newValue) =>
                _updateInputEntry(entry.key, newValue ?? false))),
      ],
    );
  }

  _updateInputEntry(TransactionOutputReference ref, bool retain) {
    setState(() {
      if (retain) {
        _selectedInputs.add(ref);
      } else {
        _selectedInputs.remove(ref);
      }
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
