import 'package:fpdart/fpdart.dart';
import 'package:giraffe_frontend/utils.dart';
import 'package:giraffe_frontend/widgets/giraffe_card.dart';
import 'package:giraffe_frontend/widgets/giraffe_scaffold.dart';
import 'package:giraffe_frontend/widgets/over_under.dart';
import 'package:giraffe_frontend/widgets/tappable_link.dart';
import 'package:giraffe_protocol/protocol.dart';
import 'package:go_router/go_router.dart';

import '../../providers/blockchain_client.dart';
import '../bitmap_render.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:intl/intl.dart';

class UnloadedBlockPage extends ConsumerWidget {
  final BlockId id;

  const UnloadedBlockPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
        future: ref.watch(podBlockchainClientProvider)!.getFullBlock(id),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data != null) {
              return BlockPage(block: snapshot.data!);
            } else {
              return GiraffeScaffold(title: "Block View", body: notFound);
            }
          } else {
            return GiraffeScaffold(title: "Block View", body: loading);
          }
        });
  }

  static final notFound = Container(
    alignment: Alignment.center,
    child: const Text("Block not found."),
  );

  static final loading = Container(
    alignment: Alignment.center,
    child: const CircularProgressIndicator(),
  );
}

class BlockPage extends StatelessWidget {
  final FullBlock block;

  const BlockPage({super.key, required this.block});
  @override
  Widget build(BuildContext context) => GiraffeScaffold(
        title: "Block View",
        body: _body(context),
      );

  _body(BuildContext context) => GiraffeCard(
        child: Column(
          children: [
            BlockIdCard(block: block, scale: 1.25).pad16,
            _blockMetadataCard(context).pad16,
            _transactionsCard(context).pad16,
          ],
        ),
      );

  Widget _blockMetadataCard(BuildContext context) {
    return Wrap(
      children: [
        _overUnder("Height", block.header.height.toString()),
        _overUnder("Slot", block.header.slot.toString()),
        _overUnder(
          "Timestamp",
          DateFormat().format(_headerDateTime()),
        ),
        StreamBuilder(
          stream: Stream.periodic(const Duration(seconds: 1)),
          builder: (context, snapshot) => _overUnder(
            "Minted",
            GetTimeAgo.parse(_headerDateTime()),
          ),
        ),
        OverUnder(
            over: const Text(
              "Parent",
              style: _defaultOverStyle,
            ),
            under: block.header.height > 1
                ? _parentLink(context)
                : const Icon(Icons.account_tree)),
      ].intersperse(const VerticalDivider()).toList(),
    );
  }

  _parentLink(BuildContext context) {
    return TappableLink(
      route: "/blocks/${block.header.parentHeaderId.show}",
      child: SizedBox.square(
        dimension: 32,
        child: BitMapViewer.forBlock(block.header.parentHeaderId),
      ),
    );
  }

  Widget _transactionsCard(BuildContext context) {
    if (block.fullBody.transactions.isEmpty) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Empty Block",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          Icon(Icons.money_off, size: 48),
        ],
      );
    }
    return Column(children: [
      OverUnder(
          over: const Text(
            "Transactions",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          under: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text("ID")),
              ],
              rows: block.fullBody.transactions
                  .map((t) => DataRow(cells: [
                        DataCell(TextButton(
                          child: SizedBox.square(
                              dimension: 32,
                              child: BitMapViewer.forTransaction(t.id)),
                          onPressed: () =>
                              context.push("/transactions/${t.id.show}"),
                        )),
                      ]))
                  .toList(),
            ),
          ))
    ]);
  }

  DateTime _headerDateTime() {
    return DateTime.fromMillisecondsSinceEpoch(block.header.timestamp.toInt());
  }

  static const TextStyle _defaultOverStyle =
      TextStyle(fontWeight: FontWeight.bold);
  static const TextStyle _defaultUnderStyle = TextStyle(color: Colors.blueGrey);

  Widget _overUnder(String overText, String underText) => OverUnder(
        over: Text(overText, style: _defaultOverStyle),
        under: Text(underText, style: _defaultUnderStyle),
      );
}

class BlockIdCard extends StatelessWidget {
  const BlockIdCard({
    super.key,
    required this.block,
    this.scale = 1.0,
  });

  final FullBlock block;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        SizedBox.square(
                dimension: 48 * scale,
                child: BitMapViewer.forBlock(block.header.id))
            .pad(4 * scale),
        OverUnder(
          over: Text("Block ID",
              style: TextStyle(
                fontSize: 16 * scale,
                fontWeight: FontWeight.bold,
              )).pad(2 * scale),
          under: Text(
            block.header.id.show,
            style: TextStyle(
              fontSize: 13 * scale,
              color: Colors.blueGrey,
            ),
          ),
        ).pad(2 * scale),
      ],
    );
  }
}
