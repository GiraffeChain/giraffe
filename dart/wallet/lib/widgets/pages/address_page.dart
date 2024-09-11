import 'package:giraffe_wallet/providers/canonical_head.dart';
import 'package:giraffe_wallet/utils.dart';
import 'package:giraffe_wallet/widgets/giraffe_card.dart';
import 'package:giraffe_wallet/widgets/giraffe_scaffold.dart';
import 'package:giraffe_wallet/widgets/over_under.dart';

import '../../providers/blockchain_client.dart';
import '../../widgets/bitmap_render.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UnloadedAddressPage extends ConsumerWidget {
  final LockAddress address;

  const UnloadedAddressPage({super.key, required this.address});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(podCanonicalHeadProvider);
    return FutureBuilder(
        future: fetch(ref),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data != null) {
              return AddressPage(
                  address: address, outputs: snapshot.requireData);
            } else {
              return GiraffeScaffold(title: "Address View", body: notFound);
            }
          } else {
            return GiraffeScaffold(title: "Address View", body: loading);
          }
        });
  }

  Future<List<(TransactionOutputReference, TransactionOutput)>> fetch(
      WidgetRef ref) async {
    final client = ref.watch(podBlockchainClientProvider)!;
    final refs = await client.getLockAddressState(address);
    return Future.wait(refs.map(
        ((r) => client.getTransactionOutputOrRaise(r).then((o) => (r, o)))));
  }

  static final notFound = Container(
    alignment: Alignment.center,
    child: const Text("Address not found."),
  );

  static final loading = Container(
    alignment: Alignment.center,
    child: const CircularProgressIndicator(),
  );
}

class AddressPage extends StatelessWidget {
  final LockAddress address;
  final List<(TransactionOutputReference reference, TransactionOutput output)>
      outputs;

  const AddressPage({super.key, required this.address, required this.outputs});

  @override
  Widget build(BuildContext context) => GiraffeScaffold(
        title: "Address View",
        body: _body(context),
      );

  _body(BuildContext context) => GiraffeCard(
        child: ListView(
          children: [
            _addressCard().pad16,
            _outputsCard().pad16,
          ],
        ),
      );

  Widget _addressCard() {
    return Wrap(
      children: [
        SizedBox.square(
            dimension: 64, child: BitMapViewer.forLockAddress(address)),
        OverUnder(
          over: const Text("Address",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              )),
          under: Text(
            address.show,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.blueGrey,
            ),
          ),
        ),
      ],
    );
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
              DataColumn(label: Text("Graph Entry")),
              DataColumn(label: Text("Registration")),
            ],
            rows: outputs.map((rec) {
              final t = rec.$2;
              return DataRow(cells: [
                DataCell(Text(t.value.quantity.toString())),
                DataCell(t.value.hasGraphEntry()
                    ? (t.value.graphEntry.hasVertex()
                        ? const Icon(Icons.circle)
                        : const Icon(Icons.compare_arrows_outlined))
                    : Container()),
                DataCell(t.value.hasAccountRegistration()
                    ? const Icon(Icons.account_box)
                    : Container()),
              ]);
            }).toList(),
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
