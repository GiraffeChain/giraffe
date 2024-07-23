import 'package:blockchain_app/widgets/bitmap_render.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UnloadedTransactionPage extends StatelessWidget {
  final TransactionId id;

  const UnloadedTransactionPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: context.watch<BlockchainView>().getTransaction(id),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data != null) {
              return TransactionPage(transaction: snapshot.data!);
            } else {
              return _scaffold(notFound);
            }
          } else {
            return _scaffold(loading);
          }
        });
  }

  _scaffold(Widget body) =>
      Scaffold(appBar: AppBar(title: const Text("Block View")), body: body);

  static final notFound = Container(
    alignment: Alignment.center,
    child: const Text("Transaction not found."),
  );

  static final loading = Container(
    alignment: Alignment.center,
    child: const CircularProgressIndicator(),
  );
}

class TransactionPage extends StatelessWidget {
  final Transaction transaction;

  const TransactionPage({super.key, required this.transaction});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _appBar,
        body: _body(context),
      );

  get _appBar => AppBar(
        title: const Text("Transaction View"),
      );

  _body(BuildContext context) => _paddedCard(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _transactionIdCard(),
            _transactionMetadataCard(),
            Expanded(
                child: Row(
              children: [
                _inputsCard(),
                _outputsCard(),
              ],
            )),
          ],
        ),
      );

  Card _paddedCard(Widget child) => Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: child,
        ),
      );

  Card _transactionIdCard() {
    return _paddedCard(
      Row(
        children: [
          SizedBox.square(
              dimension: 64,
              child: BitMapViewer.forTransaction(transaction.id)),
          _overUnderWidgets(
              const Text("Transaction ID",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  )),
              Text(transaction.id.show,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.blueGrey,
                  ))),
        ],
      ),
    );
  }

  Card _transactionMetadataCard() {
    return _paddedCard(
      Row(
        children: [
          _paddedCard(_overUnder(
            "Reward",
            transaction.reward.toString(),
          )),
        ],
      ),
    );
  }

  Card _inputsCard() {
    return _paddedCard(Column(children: [
      _overUnderWidgets(
          const Text(
            "Inputs",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          DataTable(
            columns: const [
              DataColumn(label: Text("UTxO Reference")),
              DataColumn(label: Text("Quantity")),
              // DataColumn(label: Text("Address")), // TODO
              DataColumn(label: Text("Registration")),
            ],
            rows: transaction.inputs
                .map((t) => DataRow(cells: [
                      DataCell(Row(children: [
                        SizedBox.square(
                            dimension: 32,
                            child: BitMapViewer.forTransaction(
                                t.reference.transactionId)),
                        Text("#${t.reference.index}"),
                      ])),
                      DataCell(Text(t.value.quantity.toString())),
                      DataCell(t.value.hasAccountRegistration()
                          ? const Icon(Icons.app_registration_rounded)
                          : Container()),
                    ]))
                .toList(),
          ))
    ]));
  }

  Card _outputsCard() {
    return _paddedCard(Column(children: [
      _overUnderWidgets(
          const Text(
            "Outputs",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          DataTable(
            columns: const [
              DataColumn(label: Text("Quantity")),
              DataColumn(label: Text("Address")),
              DataColumn(label: Text("Graph Entry")),
              DataColumn(label: Text("Registration")),
            ],
            rows: transaction.outputs
                .map((t) => DataRow(cells: [
                      DataCell(Text(t.value.quantity.toString())),
                      DataCell(SizedBox.square(
                          dimension: 32,
                          child: BitMapViewer.forLockAddress(t.lockAddress))),
                      DataCell(t.value.hasGraphEntry()
                          ? (t.value.graphEntry.hasVertex()
                              ? const Icon(Icons.circle)
                              : const Icon(Icons.compare_arrows_outlined))
                          : Container()),
                      DataCell(t.value.hasAccountRegistration()
                          ? const Icon(Icons.account_box)
                          : Container()),
                    ]))
                .toList(),
          ))
    ]));
  }

  Widget _overUnder(String overText, String underText) => _overUnderWidgets(
        Text(
          overText,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(underText, style: const TextStyle(color: Colors.blueGrey)),
      );

  Widget _overUnderWidgets(Widget over, Widget under) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            over,
            const Divider(),
            under,
          ],
        ),
      );
}
