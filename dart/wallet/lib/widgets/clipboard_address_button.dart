import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giraffe_sdk/sdk.dart';

import '../providers/wallet.dart';

class ClipboardAddressButton extends ConsumerWidget {
  const ClipboardAddressButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
        future: ref.watch(podWalletProvider.future),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final addressStr = snapshot.data!.defaultLockAddress.show;
            return TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: addressStr));
                },
                label: Text(addressStr, style: const TextStyle(fontSize: 12)),
                icon: const Icon(Icons.copy));
          } else {
            return const CircularProgressIndicator();
          }
        });
  }
}
