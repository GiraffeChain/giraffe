import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:giraffe_wallet/blockchain/codecs.dart';
import 'package:giraffe_wallet/widgets/giraffe_card.dart';
import 'package:giraffe_wallet/widgets/giraffe_scaffold.dart';
import 'package:path_provider/path_provider.dart';

import '../../blockchain/genesis.dart';
import '../../blockchain/private_testnet.dart';
import '../../blockchain/staking_account.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;

class GenesisBuilderPage extends StatefulWidget {
  const GenesisBuilderPage({super.key});

  @override
  State<StatefulWidget> createState() => GenesisBuilderState();
}

class GenesisBuilderState extends State<GenesisBuilderPage> {
  String seed = "test";
  List<(LockAddress, Int64)> stakers = List.empty(growable: true);
  List<(LockAddress, Int64)> unstaked = List.empty(growable: true);
  Directory? savedDir;

  @override
  Widget build(BuildContext context) {
    return GiraffeScaffold(
      title: "Genesis Builder",
      body: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: 800,
            child: GiraffeCard(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Genesis Builder",
                    style: TextStyle(fontSize: 44, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _seedRow,
                  const Divider(),
                  _formRow("Stakers", _stakersTile),
                  const Divider(),
                  _formRow("Unstaked", _unstakedTile),
                  const Divider(),
                  _saveButton,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget get _seedRow {
    return _formRow(
        "Seed",
        SizedBox(
          width: 150,
          child: TextField(
            controller: TextEditingController(text: seed),
            onChanged: (v) => seed = v,
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

  Widget get _stakersTile {
    return Column(
      children: [
        DataTable(
          columns: _tableHeader,
          rows: stakers.mapWithIndex((e, i) => _stakerEntryRow(e, i)).toList(),
        ),
        IconButton(
            onPressed: () async {
              final address = await PrivateTestnet.defaultLockAddress;
              setState(() {
                stakers.add((address, Int64(10000)));
              });
            },
            icon: const Icon(Icons.add))
      ],
    );
  }

  Widget get _unstakedTile {
    return Column(
      children: [
        DataTable(
          columns: _tableHeader,
          rows:
              unstaked.mapWithIndex((e, i) => _unstakedEntryRow(e, i)).toList(),
        ),
        IconButton(
            onPressed: () async {
              final address = await PrivateTestnet.defaultLockAddress;
              setState(() {
                unstaked.add((address, Int64(10000)));
              });
            },
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

  DataRow _stakerEntryRow((LockAddress, Int64) entry, int index) {
    return DataRow(
      cells: [
        DataCell(TextFormField(
          initialValue: entry.$2.toString(),
          onChanged: (value) => setState(() {
            stakers[index] = (stakers[index].$1, Int64.parseInt(value));
          }),
        )),
        DataCell(TextFormField(
          initialValue: entry.$1.show,
          onChanged: (value) => setState(() {
            stakers[index] = (decodeLockAddress(value), stakers[index].$2);
          }),
        )),
        DataCell(
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => setState(() {
              stakers.removeAt(index);
            }),
          ),
        ),
      ],
    );
  }

  DataRow _unstakedEntryRow((LockAddress, Int64) entry, int index) {
    return DataRow(
      cells: [
        DataCell(TextFormField(
          initialValue: entry.$2.toString(),
          onChanged: (value) => setState(() {
            unstaked[index] = (unstaked[index].$1, Int64.parseInt(value));
          }),
        )),
        DataCell(TextFormField(
          initialValue: entry.$1.show,
          onChanged: (value) => setState(() {
            unstaked[index] = (decodeLockAddress(value), unstaked[index].$2);
          }),
        )),
        DataCell(
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => setState(() {
              unstaked.removeAt(index);
            }),
          ),
        ),
      ],
    );
  }

  Widget get _saveButton {
    final button = TextButton.icon(
      onPressed: save,
      icon: const Icon(Icons.save),
      label: const Text("Save"),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        button,
        if (savedDir != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: savedDir!.path));
              },
              label: Text(savedDir!.path,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12)),
              icon: const Icon(Icons.copy),
            ),
          )
      ],
    );
  }

  Future<void> save() async {
    final genesisInitDirectory = Directory(
        "${(await getApplicationDocumentsDirectory()).path}/blockchain/genesis-init");
    final stakerEntries = await Future.wait(stakers.mapWithIndex((e, index) {
      return StakingAccount.generate(
          e.$2, e.$1, utf8.encode(seed + index.toString()));
    }).toList());
    final unstakedTransaction = Transaction(
        outputs: unstaked
            .map((t) => TransactionOutput(lockAddress: t.$1, quantity: t.$2)));
    final genesisTransactions = [
      unstakedTransaction,
      ...stakerEntries.map((s) => s.transaction)
    ];
    final genesisConfig = GenesisConfig(
        Int64(DateTime.now().millisecondsSinceEpoch),
        genesisTransactions,
        [],
        ProtocolSettings.defaultAsMap);
    final genesis = genesisConfig.block;

    final saveDir =
        Directory("${genesisInitDirectory.path}/${genesis.header.id.show}");
    await Directory("${saveDir.path}/stakers").create(recursive: true);
    await Future.wait(stakerEntries.mapWithIndex((s, index) =>
        File("${saveDir.path}/stakers/$index")
            .writeAsString(s.stakerData.serialized)));
    await Genesis.save(saveDir, genesis);
    setState(() {
      savedDir = saveDir;
    });
  }
}
