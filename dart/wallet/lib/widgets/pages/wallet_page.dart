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

class StreamedTransactView extends ConsumerWidget {
  const StreamedTransactView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GiraffeScaffold(
      title: "Wallet",
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 600,
          child: GiraffeCard(
            child: body(context, ref),
          ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Address",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
            .pad8,
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
  String _to = "";
  String _amount = "";
  String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("Transfer Funds",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
            .pad8,
        TextField(
          decoration: const InputDecoration(labelText: "To"),
          onChanged: (str) {
            error = null;
            _to = str;
          },
        ).pad8,
        TextField(
          decoration: const InputDecoration(labelText: "Amount"),
          onChanged: (str) {
            error = null;
            _amount = str;
          },
        ).pad8,
        errorWidget(),
        submitButton(),
      ],
    );
  }

  Widget errorWidget() {
    if (error == null) {
      return const SizedBox();
    }
    return Text(error!, style: const TextStyle(color: Colors.red));
  }

  Widget submitButton() {
    final Function()? onPressed = error == null
        ? () async {
            final amount = Int64.tryParseInt(_amount);
            if (amount == null) {
              setState(() => error = "Invalid amount");
              return;
            }
            final to = decodeLockAddress(_to);
            if (to == null) {
              setState(() => error = "Invalid address");
              return;
            }
            final client = ref.read(podBlockchainClientProvider)!;
            final wallet = await ref.read(podWalletProvider.future);
            final tx = await wallet.payAndAttest(
                client,
                Transaction(outputs: [
                  TransactionOutput(
                      lockAddress: to, value: Value(quantity: amount))
                ]));
            await client.broadcastTransaction(tx);
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
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            OverUnder(
                over: const Text("Total Funds",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                under: Text(value.totalFunds.toString())),
            OverUnder(
                over: const Text("Staked Funds",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                under: Text(value.stakedFunds.toString())),
            OverUnder(
                over: const Text("Liquid Funds",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                under: Text(value.liquidFunds.toString())),
          ],
        );
      case AsyncError(:final error):
        return Center(child: Text("An error occurred: $error"));
      default:
        return const Center(child: CircularProgressIndicator());
    }
  }
}
