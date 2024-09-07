import 'package:giraffe_wallet/utils.dart';
import 'package:giraffe_wallet/widgets/giraffe_background.dart';
import 'package:giraffe_wallet/widgets/giraffe_card.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlockchainPage extends ConsumerWidget {
  const BlockchainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        body: GiraffeBackground(
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 600,
          child: GiraffeCard(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              searchBox(context, ref).pad16,
              navigationBlock(context, ref).pad16,
            ]),
          ),
        ),
      ),
    ));
  }

  Widget searchBox(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    return Row(children: [
      Expanded(
          child: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: "Search"))),
      IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            final id = controller.text;
            if (id.isNotEmpty) {
              FluroRouter.appRouter.navigateTo(context, "/blocks/$id");
            }
          })
    ]);
  }

  Widget navigationBlock(BuildContext context, WidgetRef ref) {
    return Column(
        children: [
      ElevatedButton.icon(
          label: const Text("Wallet"),
          icon: const Icon(Icons.wallet),
          onPressed: () {
            FluroRouter.appRouter.navigateTo(context, "/wallet");
          }),
      ElevatedButton.icon(
          label: const Text("Social"),
          icon: const Icon(Icons.people),
          onPressed: () {
            FluroRouter.appRouter.navigateTo(context, "/social");
          }),
      ElevatedButton.icon(
          label: const Text("Stake"),
          icon: const Icon(Icons.publish),
          onPressed: () {
            FluroRouter.appRouter.navigateTo(context, "/stake");
          }),
    ].padAll16);
  }
}
