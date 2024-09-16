import 'package:giraffe_sdk/sdk.dart';
import 'package:giraffe_wallet/providers/blockchain_client.dart';
import 'package:giraffe_wallet/providers/canonical_head.dart';
import 'package:giraffe_wallet/utils.dart';
import 'package:giraffe_wallet/widgets/giraffe_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giraffe_wallet/widgets/giraffe_scaffold.dart';
import 'package:giraffe_wallet/widgets/search_box.dart';
import 'package:go_router/go_router.dart';

class BlockchainPage extends ConsumerWidget {
  const BlockchainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GiraffeScaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 600,
          child: GiraffeCard(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text("Giraffe Chain",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              headInfo(context, ref),
              navigationBlock(context, ref).pad16,
              const SearchBox().pad16,
            ]),
          ),
        ),
      ),
    );
  }

  Widget navigationBlock(BuildContext context, WidgetRef ref) {
    return Wrap(
        children: [
      ElevatedButton.icon(
          // style: buttonStyle,
          label: const Text("Wallet"),
          icon: const Icon(Icons.wallet),
          onPressed: () {
            context.push("/wallet");
          }),
      ElevatedButton.icon(
          // style: buttonStyle,
          label: const Text("Social"),
          icon: const Icon(Icons.people),
          onPressed: () {
            context.push("/social");
          }),
      ElevatedButton.icon(
          // style: buttonStyle,
          label: const Text("Stake"),
          icon: const Icon(Icons.publish),
          onPressed: () {
            context.push("/stake");
          }),
    ].padAll8);
  }

  Widget headInfo(BuildContext context, WidgetRef ref) {
    final client = ref.watch(podBlockchainClientProvider);
    if (client == null) {
      return const Center(child: Text("Not initialized"));
    }
    final head = ref.watch(podCanonicalHeadProvider);

    switch (head) {
      case AsyncData(:final value):
        return FutureBuilder(
            future: client.getBlockHeaderOrRaise(value),
            builder: (context, snapshot) => snapshot.hasData
                ? MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        context.push("/blocks/${value.show}");
                      },
                      child: SizedBox(
                        height: 48,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Chain Tip ID",
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0x99000000),
                                          fontWeight: FontWeight.bold)),
                                  Flexible(
                                    child: Text(value.show,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0x99000000))),
                                  ),
                                ],
                              ),
                            ),
                            const VerticalDivider(),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Height",
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0x99000000),
                                          fontWeight: FontWeight.bold)),
                                  Text(snapshot.data!.height.toString(),
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0x99000000))),
                                ]),
                          ],
                        ),
                      ),
                    ),
                  )
                : const CircularProgressIndicator());

      case AsyncError(:final error):
        return Text("An error occurred: $error");
      default:
        return const Center(child: CircularProgressIndicator());
    }
  }
}
