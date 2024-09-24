import 'package:fixnum/fixnum.dart';
import 'package:giraffe_wallet/utils.dart';
import 'package:giraffe_wallet/widgets/clipboard_address_button.dart';
import 'package:giraffe_wallet/widgets/giraffe_card.dart';
import 'package:giraffe_wallet/widgets/giraffe_scaffold.dart';
import 'package:giraffe_wallet/widgets/over_under.dart';

import '../../providers/blockchain_client.dart';
import '../../providers/wallet.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bitmap_render.dart';
import '../tappable_link.dart';

class StreamedTransactView extends ConsumerWidget {
  const StreamedTransactView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GiraffeScaffold(
      title: "Wallet",
      body: Align(
        alignment: Alignment.topLeft,
        child: GiraffeCard(
          child: SizedBox(width: 600, height: 500, child: body(context, ref)),
        ),
      ),
    );
  }

  Widget body(BuildContext context, WidgetRef ref) {
    final client = ref.watch(podBlockchainClientProvider);
    if (client == null) {
      return const Center(child: Text("Not initialized"));
    }
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
  const TransactView({
    super.key,
    required this.wallet,
    required this.client,
  });

  final Wallet wallet;
  final BlockchainClient client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            TappableLink(
              route: "/addresses/${wallet.defaultLockAddress.show}",
              child: SizedBox.square(
                  dimension: 32,
                  child:
                      BitMapViewer.forLockAddress(wallet.defaultLockAddress)),
            ).pad8,
            const Text("Address",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                .pad8,
          ],
        ),
        const ClipboardAddressButton().pad8,
        const WalletBalances().pad8,
        const Divider(),
        const TransferFunds().pad8,
      ],
    );
  }
}

class TransferFunds extends ConsumerStatefulWidget {
  const TransferFunds({super.key});

  @override
  TransferFundsState createState() => TransferFundsState();
}

class TransferFundsState extends ConsumerState<TransferFunds> {
  String toAddress = "";
  String quantity = "";
  String? toError = "Enter a valid address";
  String? quantityError = "Enter a valid quantity";
  String? transferError;
  Transaction? broadcastedTransaction;

  @override
  Widget build(BuildContext context) {
    if (broadcastedTransaction != null) {
      return transferring(context, broadcastedTransaction!);
    } else {
      return transferForm(context);
    }
  }

  Widget transferForm(BuildContext context) {
    return Column(
      children: [
        const Text("Transfer Funds",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
            .pad8,
        TextField(
          decoration: const InputDecoration(labelText: "To"),
          onChanged: (str) {
            toAddress = str;
            checkLockAddress();
          },
        ).pad8,
        TextField(
          decoration: const InputDecoration(labelText: "Quantity"),
          onChanged: (str) {
            quantity = str;
            checkQuantity();
          },
        ).pad8,
        errorWidget(),
        submitButton(),
      ],
    );
  }

  Widget transferring(
      BuildContext context, Transaction broadcastedTransaction) {
    return Column(
      children: [
        const Text("Transferring Funds",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
            .pad8,
        const CircularProgressIndicator().pad8,
        Text(
          broadcastedTransaction.id.show,
          style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 11,
              fontWeight: FontWeight.bold),
        ).pad8,
      ],
    );
  }

  checkQuantity() {
    final amount = Int64.tryParseInt(quantity);
    if (amount == null) {
      setState(() => quantityError = "Invalid quantity");
    } else if (quantityError != null) {
      setState(() => quantityError = null);
    }
  }

  checkLockAddress() {
    try {
      decodeLockAddress(toAddress);
      if (toError != null) {
        setState(() => toError = null);
      }
    } catch (e) {
      setState(() => toError = "Invalid address");
    }
  }

  List<String> get allErrors => [
        if (toError != null) toError!,
        if (quantityError != null) quantityError!,
        if (transferError != null) transferError!,
      ];

  Widget errorWidget() {
    final errors = allErrors;
    if (errors.isEmpty) {
      return const SizedBox();
    }
    errorText(String error) =>
        Text(error, style: const TextStyle(color: Colors.red));
    if (errors.length == 1) {
      return errorText(errors.first);
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: errors.map((e) => errorText(e)).toList(),
      );
    }
  }

  Widget submitButton() {
    final errors = allErrors;
    final Function()? onPressed = errors.isEmpty
        ? () async {
            final amount = Int64.parseInt(quantity);
            final LockAddress to = decodeLockAddress(toAddress);
            final client = ref.read(podBlockchainClientProvider)!;
            final wallet = await ref.read(podWalletProvider.future);
            final tx = await wallet.payAndAttest(
                client,
                Transaction(outputs: [
                  TransactionOutput(
                      lockAddress: to, value: Value(quantity: amount))
                ]));
            setState(() {
              broadcastedTransaction = tx;
            });
            try {
              await client.broadcastTransaction(tx);
              await client.confirmTransaction(tx.id);
            } catch (e) {
              setState(() {
                transferError = "Failed to broadcast transaction: $e";
              });
              return;
            }
            setState(() {
              transferError = null;
              broadcastedTransaction = null;
            });
          }
        : null;
    return ElevatedButton.icon(
        onPressed: onPressed,
        label: const Text("Send"),
        icon: const Icon(Icons.send));
  }
}

class WalletBalances extends ConsumerWidget {
  const WalletBalances({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (ref.watch(podWalletProvider)) {
      case AsyncData(:final value):
        return Wrap(
          children: [
            SizedBox(
                width: 120,
                child: OverUnder(
                    over: const Text("Total Funds",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    under: Text(value.totalFunds.toString()))),
            SizedBox(
                width: 120,
                child: OverUnder(
                    over: const Text("Staked Funds",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    under: Text(value.stakedFunds.toString()))),
            SizedBox(
                width: 120,
                child: OverUnder(
                    over: const Text("Liquid Funds",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    under: Text(value.liquidFunds.toString()))),
          ],
        );
      case AsyncError(:final error):
        return Center(child: Text("An error occurred: $error"));
      default:
        return const Center(child: CircularProgressIndicator());
    }
  }
}
