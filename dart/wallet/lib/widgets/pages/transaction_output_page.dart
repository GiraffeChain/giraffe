import 'package:flutter_json_view/flutter_json_view.dart';
import 'package:fpdart/fpdart.dart';
import 'package:giraffe_wallet/utils.dart';
import 'package:giraffe_wallet/widgets/giraffe_card.dart';
import 'package:giraffe_wallet/widgets/giraffe_scaffold.dart';
import 'package:giraffe_wallet/widgets/over_under.dart';

import '../../providers/blockchain_client.dart';
import '../../widgets/bitmap_render.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../tappable_link.dart';

class UnloadedTransactionOutputPage extends ConsumerWidget {
  final TransactionOutputReference reference;

  const UnloadedTransactionOutputPage({super.key, required this.reference});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
        future: ref
            .watch(podBlockchainClientProvider)!
            .getTransactionOutput(reference),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data != null) {
              return TransactionOutputPage(
                  reference: reference, output: snapshot.data!);
            } else {
              return GiraffeScaffold(
                  title: "Transaction Output View", body: notFound);
            }
          } else {
            return GiraffeScaffold(
                title: "Transaction Output View", body: loading);
          }
        });
  }

  static final notFound = Container(
    alignment: Alignment.center,
    child: const Text("Transaction Output not found."),
  );

  static final loading = Container(
    alignment: Alignment.center,
    child: const CircularProgressIndicator(),
  );
}

class TransactionOutputPage extends StatelessWidget {
  final TransactionOutputReference reference;
  final TransactionOutput output;

  const TransactionOutputPage(
      {super.key, required this.reference, required this.output});

  @override
  Widget build(BuildContext context) => GiraffeScaffold(
        title: "Transaction Output View",
        body: _body(context),
      );

  _body(BuildContext context) => GiraffeCard(
        child: Column(
          children: [
            TransactionOutputIdCard(reference: reference, scale: 1.25).pad16,
            _quantity().pad16,
            if (output.value.hasAccountRegistration()) _registration().pad16,
            if (output.value.hasGraphEntry()) _graphEntry().pad16,
          ],
        ),
      );

  Widget _quantity() {
    return OverUnder(
        over: const Text("Quantity",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        under: Text(output.value.quantity.toString(),
            style: const TextStyle(fontSize: 14, color: Colors.blueGrey)));
  }

  Widget _registration() {
    final registration = output.value.accountRegistration;
    final body = <Widget>[];
    if (registration.hasAssociationLock()) {
      body.add(OverUnder(
          over: const Text("Association Lock",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          under: TappableLink(
            route: "/addresses/${registration.associationLock.show}",
            child: SizedBox.square(
                dimension: 32,
                child:
                    BitMapViewer.forLockAddress(registration.associationLock)),
          )));
    }
    if (registration.hasStakingRegistration()) {
      final stakingRegistration = registration.stakingRegistration;
      body.add(OverUnder(
          over: const Text("Staking VK",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          under: Text(stakingRegistration.vk,
              style: const TextStyle(fontSize: 14, color: Colors.blueGrey))));
      body.add(OverUnder(
          over: const Text("Staking Signature",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          under: Text(stakingRegistration.commitmentSignature,
              style: const TextStyle(fontSize: 14, color: Colors.blueGrey))));
    }
    return OverUnder(
        over: const Text("Registration",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        under:
            Wrap(children: body.intersperse(const VerticalDivider()).toList()));
  }

  Widget _graphEntry() {
    final graphEntry = output.value.graphEntry;
    if (graphEntry.hasVertex()) {
      final vertex = graphEntry.vertex;
      return OverUnder(
        over: const Text("Vertex",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        under: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            OverUnder(
                over: const Text("Label",
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                under: Text(vertex.label,
                    style:
                        const TextStyle(fontSize: 14, color: Colors.blueGrey))),
            if (vertex.hasData()) const Divider(),
            if (vertex.hasData())
              OverUnder(
                over: const Text("Data",
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                under: DataRenderer(data: vertex.data.toProto3Json()),
              ),
          ],
        ),
      );
    } else if (graphEntry.hasEdge()) {
      final edge = graphEntry.edge;
      return OverUnder(
        over: const Text("Edge",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        under: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            OverUnder(
                over: const Text("Label",
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                under: Text(edge.label,
                    style:
                        const TextStyle(fontSize: 14, color: Colors.blueGrey))),
            const Divider(),
            if (edge.hasData())
              OverUnder(
                over: const Text("Data",
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                under: DataRenderer(data: edge.data.toProto3Json()),
              ),
            if (edge.hasData()) const Divider(),
            Wrap(
              children: [
                OverUnder(
                    over: const Text("Vertex A",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    under: TransactionOutputIdCard(
                        reference: edge.a
                            .withoutSelfReference(reference.transactionId),
                        tappable: true)),
                const Divider(),
                OverUnder(
                    over: const Text("Vertex B",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    under: TransactionOutputIdCard(
                        reference: edge.b
                            .withoutSelfReference(reference.transactionId),
                        tappable: true)),
              ],
            ),
          ],
        ).pad(4),
      );
    }
    throw ArgumentError.notNull("graphEntry");
  }
}

class TransactionOutputIdCard extends StatelessWidget {
  const TransactionOutputIdCard(
      {super.key,
      required this.reference,
      this.scale = 1.0,
      this.tappable = false});

  final TransactionOutputReference reference;
  final double scale;
  final bool tappable;

  @override
  Widget build(BuildContext context) {
    if (tappable) {
      return TappableLink(
          route:
              "/transactions/${reference.transactionId.show}/${reference.index}",
          child: wrapped());
    }
    return wrapped();
  }

  Widget wrapped() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox.square(
            dimension: 48 * scale,
            child: BitMapViewer.forTransaction(reference.transactionId)
                .pad(4 * scale)),
        OverUnder(
          over: OverUnder(
            over: Text("Transaction ID",
                style: TextStyle(
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.bold,
                )),
            under: Text(
              reference.transactionId.show,
              style: TextStyle(
                fontSize: 10 * scale,
                color: Colors.blueGrey,
              ),
            ),
          ).pad(2 * scale),
          under: OverUnder(
            over: Text("Index",
                style: TextStyle(
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.bold,
                )),
            under: Text(
              reference.index.toString(),
              style: TextStyle(
                fontSize: 10 * scale,
                color: Colors.blueGrey,
              ),
            ),
          ).pad(2 * scale),
        ).pad(4 * scale),
      ],
    );
  }
}

class DataRenderer extends StatelessWidget {
  final Object? data;

  const DataRenderer({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return JsonView.map(
      data as Map<String, dynamic>,
      theme: jsonViewTheme,
    );
  }

  static const jsonViewTheme = JsonViewTheme(
    backgroundColor: Colors.transparent,
    defaultTextStyle: TextStyle(fontSize: 13, color: Colors.blueGrey),
    keyStyle: TextStyle(
        fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.bold),
    doubleStyle: TextStyle(fontSize: 13, color: Colors.blueGrey),
    intStyle: TextStyle(fontSize: 13, color: Colors.blueGrey),
    stringStyle: TextStyle(fontSize: 13, color: Colors.blueGrey),
    boolStyle: TextStyle(fontSize: 13, color: Colors.blueGrey),
  );
}
