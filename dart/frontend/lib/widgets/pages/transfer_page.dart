import 'package:fast_base58/fast_base58.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:giraffe_sdk/sdk.dart';
import 'package:giraffe_frontend/providers/wallet.dart';
import 'package:giraffe_frontend/utils.dart';
import 'package:giraffe_frontend/widgets/giraffe_card.dart';
import 'package:giraffe_frontend/widgets/giraffe_scaffold.dart';
import 'package:giraffe_frontend/widgets/over_under.dart';
import 'package:giraffe_frontend/widgets/pages/transaction_output_page.dart';
import 'package:go_router/go_router.dart';

import '../../providers/blockchain_client.dart';
import '../bitmap_render.dart';
import '../tappable_link.dart';

class TransferPage extends ConsumerWidget {
  final String transferData;

  const TransferPage({super.key, required this.transferData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget child;
    switch (ref.watch(podWalletProvider)) {
      case AsyncData(:final value):
        final client = ref.watch(podBlockchainClientProvider);
        if (client == null) {
          child = uninitialized(context);
        } else {
          child = body(client, value);
        }
        break;
      default:
        child = uninitialized(context);
    }
    return GiraffeScaffold(title: "Transfer", body: child);
  }

  Widget uninitialized(BuildContext context) => GiraffeCard(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Giraffe Wallet has not been initialized.",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold))
            .pad8,
        const Text(
                "Please navigate to the settings page to create a wallet and specify an API endpoint.",
                style: TextStyle(fontSize: 16))
            .pad8,
        ElevatedButton.icon(
                onPressed: () => context.push("/"),
                label: const Text("Settings"),
                icon: const Icon(Icons.settings))
            .pad8,
      ],
    ),
  );

  Widget body(BlockchainClient client, Wallet wallet) {
    try {
      final tx = decoded;
      return GiraffeCard(
        child: Column(
          children: [
            _inputsCard(tx).pad16,
            _outputsCard(tx).pad16,
            Center(
              child: PayAndAttestButton(
                  transaction: tx, client: client, wallet: wallet),
            ).pad16,
          ],
        ),
      );
    } catch (e) {
      return GiraffeCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Invalid Input',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(e.toString()),
          ],
        ),
      );
    }
  }

  Transaction get decoded {
    final List<int> b58;
    try {
      b58 = Base58Decode(transferData);
    } catch (e) {
      throw ArgumentError("Transfer data is not valid base58");
    }
    try {
      return Transaction.fromBuffer(b58);
    } catch (e) {
      throw ArgumentError("Transfer data is not a valid transaction");
    }
  }

  Widget get header {
    return const Text("Transfer Request",
        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold));
  }

  Widget get subHeader {
    return const Text("Transaction Details",
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold));
  }

  Widget _inputsCard(Transaction transaction) {
    return OverUnder(
        over: const Text(
          "Inputs",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        under: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text("Reference")),
            ],
            rows: transaction.inputs
                .map((t) => DataRow(cells: [
                      DataCell(TransactionOutputIdCard(
                          reference: t.reference, tappable: true)),
                    ]))
                .toList(),
          ),
        ));
  }

  Widget _outputsCard(Transaction transaction) {
    return OverUnder(
        over: const Text(
          "Outputs",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        under: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text("Quantity"), numeric: true),
              DataColumn(label: Text("Address")),
              DataColumn(label: Text("Graph Entry")),
              DataColumn(label: Text("Registration")),
            ],
            rows: transaction.outputs
                .mapWithIndex((t, index) => DataRow(cells: [
                      DataCell(Text(t.quantity.toString())),
                      DataCell(TappableLink(
                        route: "/addresses/${t.lockAddress.show}",
                        child: SizedBox.square(
                            dimension: 32,
                            child: BitMapViewer.forLockAddress(t.lockAddress)),
                      )),
                      DataCell(t.hasGraphEntry()
                          ? (t.graphEntry.hasVertex()
                              ? const Icon(Icons.circle)
                              : const Icon(Icons.compare_arrows_outlined))
                          : Container()),
                      DataCell(t.hasAccountRegistration()
                          ? const Icon(Icons.account_box)
                          : Container()),
                    ]))
                .toList(),
          ),
        ));
  }
}

class PayAndAttestButton extends StatefulWidget {
  final Transaction transaction;
  final BlockchainClient client;
  final Wallet wallet;

  const PayAndAttestButton(
      {super.key,
      required this.transaction,
      required this.client,
      required this.wallet});

  @override
  State<PayAndAttestButton> createState() => _PayAndAttestButtonState();
}

class _PayAndAttestButtonState extends State<PayAndAttestButton> {
  String? error;
  Transaction? broadcastedTx;
  bool done = false;
  @override
  Widget build(BuildContext context) {
    if (done) {
      return const Icon(Icons.check, color: Colors.green);
    }
    if (error != null) {
      return Text(error!, style: const TextStyle(color: Colors.red));
    }
    if (broadcastedTx != null) {
      return const CircularProgressIndicator();
    }
    return ElevatedButton.icon(
      onPressed: () async {
        try {
          final tx = await widget.wallet
              .payAndAttest(widget.client, widget.transaction);
          setState(() => broadcastedTx = tx);
          await widget.client.broadcastTransaction(tx);
          await widget.client.confirmTransaction(tx.id);
          setState(() {
            done = true;
          });
        } catch (e) {
          setState(() {
            error = e.toString();
          });
        }
      },
      icon: const Icon(Icons.send),
      label: const Text("Pay, Sign, Broadcast"),
    );
  }
}
