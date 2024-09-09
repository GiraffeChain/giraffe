import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giraffe_wallet/widgets/giraffe_card.dart';
import 'package:giraffe_wallet/widgets/giraffe_scaffold.dart';

import 'genesis_builder_page.dart';

class AdvancedPage extends ConsumerWidget {
  const AdvancedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GiraffeScaffold(title: "Advanced", body: body(context, ref));
  }

  Widget body(BuildContext context, WidgetRef ref) {
    return GiraffeCard(
        child: Column(
      children: [
        const Text("Advanced Settings and Features",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            )),
        const Text("Warning: This area is intended for developers and testers.",
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
        const Divider(),
        ElevatedButton.icon(
            label: const Text("Genesis Builder"),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const GenesisBuilderPage())),
            icon: const Icon(Icons.baby_changing_station))
      ],
    ));
  }
}
