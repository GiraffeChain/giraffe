import 'dart:async';

import 'package:blockchain/blockchain_view.dart';
import 'package:blockchain/codecs.dart';
import 'package:blockchain/ledger/models/transaction_validation_context.dart';
import 'package:blockchain/ledger/utils.dart';
import 'package:blockchain_app/widgets/pages/blockchain_launcher_page.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain/wallet/wallet.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:flutter/services.dart';

class StreamedTransactView extends StatefulWidget {
  final BlockchainView view;
  final BlockchainWriter writer;

  const StreamedTransactView(
      {super.key, required this.view, required this.writer});
  @override
  State<StatefulWidget> createState() => StreamedTransactViewState();
}

class StreamedTransactViewState extends State<StreamedTransactView>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder(
      stream: Wallet.streamed(widget.view),
      builder: (context, snapshot) => snapshot.hasData
          ? TransactView(
              wallet: snapshot.data!,
              view: widget.view,
              writer: widget.writer,
            )
          : const CircularProgressIndicator(),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class TransactView extends StatefulWidget {
  final Wallet wallet;
  final BlockchainView view;
  final BlockchainWriter writer;

  const TransactView(
      {super.key,
      required this.wallet,
      required this.view,
      required this.writer});
  @override
  State<StatefulWidget> createState() => TransactViewState();
}

class TransactViewState extends State<TransactView> {
  Set<TransactionOutputReference> _selectedInputs = {};
  List<(String valueStr, String addressStr)> _newOutputEntries = [];

  @override
  Widget build(BuildContext context) {
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
      .map((v) => v.quantity)
      .fold(Int64.ZERO, (a, b) => a + b);

  Future<Transaction> _createTransaction() async {
    var tx = Transaction();

    for (final ref in _selectedInputs) {
      final output = widget.wallet.spendableOutputs[ref]!;
      final input = TransactionInput()
        ..value = output.value
        ..reference = ref;
      tx.inputs.add(input);
    }

    for (final e in _newOutputEntries) {
      final lockAddress = decodeLockAddress(e.$2);
      final value = Value()..quantity = Int64.parseInt(e.$1);
      final output = TransactionOutput()
        ..lockAddress = lockAddress
        ..value = value;
      tx.outputs.add(output);
    }
    final witnessContext = WitnessContext(
        height: Int64.ONE, slot: Int64.ONE, messageToSign: tx.immutableBytes);
    for (final lockAddress
        in await tx.requiredWitnesses(widget.view.getTransactionOrRaise)) {
      final signer = widget.wallet.signers[lockAddress]!;
      final witness = await signer(witnessContext);
      tx.attestation.add(witness);
    }

    return tx;
  }

  _transact() async {
    final tx = await _createTransaction();
    await widget.writer.submitTransaction(tx);
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
            ..._newOutputEntries.mapWithIndex(_outputEntryRow),
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

  DataRow _outputEntryRow((String, String) entry, int index) {
    return DataRow(
      cells: [
        DataCell(TextFormField(
          initialValue: entry.$1,
          onChanged: (value) => _updateOutputEntryQuantity(index, value),
        )),
        DataCell(TextFormField(
          initialValue: entry.$2,
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
    Int64 outputSum = Int64.ZERO;
    String? errorText;
    for (final t in _newOutputEntries) {
      final parsed = Int64.tryParseInt(t.$1);
      if (parsed == null) {
        errorText = "?";
        break;
      } else {
        outputSum += parsed;
      }
    }

    return DataRow(cells: [
      DataCell(Text(errorText ?? (_inputSum() - outputSum).toString())),
      const DataCell(Text("Tip")),
      const DataCell(IconButton(
        icon: Icon(Icons.cancel),
        onPressed: null,
      )),
    ]);
  }

  _updateOutputEntryQuantity(int index, String value) {
    setState(() {
      final (_, a) = _newOutputEntries[index];
      _newOutputEntries[index] = (value, a);
    });
  }

  _updateOutputEntryAddress(int index, String value) {
    setState(() {
      final (v, _) = _newOutputEntries[index];
      _newOutputEntries[index] = (v, value);
    });
  }

  _addOutputEntry() {
    setState(() {
      _newOutputEntries.add(const ("100", ""));
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
                    // Hide registrations for now
                    .where((e) => !e.value.value.hasRegistration())
                    .map(_inputEntryRow)
                    .toList(),
              ));
  }

  DataRow _inputEntryRow(
      MapEntry<TransactionOutputReference, TransactionOutput> entry) {
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
