import 'package:giraffe_wallet/utils.dart';
import 'package:giraffe_wallet/widgets/giraffe_card.dart';
import 'package:giraffe_wallet/widgets/giraffe_scaffold.dart';
import 'package:giraffe_wallet/widgets/over_under.dart';

import '../../providers/blockchain_client.dart';
import '../../widgets/bitmap_render.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UnloadedTransactionPage extends ConsumerWidget {
  final TransactionId id;

  const UnloadedTransactionPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
        future: ref.watch(podBlockchainClientProvider)!.getTransaction(id),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data != null) {
              return TransactionPage(transaction: snapshot.data!);
            } else {
              return GiraffeScaffold(title: "Transaction View", body: notFound);
            }
          } else {
            return GiraffeScaffold(title: "Transaction View", body: loading);
          }
        });
  }

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
  Widget build(BuildContext context) => GiraffeScaffold(
        title: "Transaction View",
        body: _body(context),
      );

  _body(BuildContext context) => GiraffeCard(
        child: ListView(
          children: [
            _transactionIdCard().pad16,
            _transactionMetadataCard().pad16,
            _inputsCard().pad16,
            _outputsCard().pad16,
          ],
        ),
      );

  Widget _transactionIdCard() {
    return Wrap(
      children: [
        SizedBox.square(
            dimension: 64, child: BitMapViewer.forTransaction(transaction.id)),
        OverUnder(
          over: const Text("Transaction ID",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              )),
          under: Text(
            transaction.id.show,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.blueGrey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _transactionMetadataCard() {
    return _overUnder(
      "Reward",
      transaction.reward.toString(),
    );
  }

  Widget _inputsCard() {
    return _overUnderWidgets(
        const Text(
          "Inputs",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
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
          ),
        ));
  }

  Widget _outputsCard() {
    return _overUnderWidgets(
        const Text(
          "Outputs",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
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
          ),
        ));
  }

  Widget _overUnder(String overText, String underText) => _overUnderWidgets(
        Text(
          overText,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(underText, style: const TextStyle(color: Colors.blueGrey)),
      );

  Widget _overUnderWidgets(Widget over, Widget under) =>
      OverUnder(over: over, under: under);
}
