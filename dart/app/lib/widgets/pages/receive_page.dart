import 'package:blockchain_app/providers/wallet.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReceiveView extends ConsumerWidget {
  const ReceiveView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(podWalletProvider);
    return switch (wallet) {
      AsyncData(:final value) => displayAddress(value),
      AsyncError(:final error) => displayError(error),
      _ => const Center(
          child: CircularProgressIndicator(),
        )
    };
  }

  Widget displayAddress(Wallet wallet) {
    final addressStr = wallet.defaultLockAddress.show;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Your address is:", style: TextStyle(fontSize: 18)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: addressStr));
              },
              label: Text(addressStr, style: const TextStyle(fontSize: 12)),
              icon: const Icon(Icons.copy)),
        ),
      ],
    );
  }

  Widget displayError(Object e) => Text(e.toString());
}
