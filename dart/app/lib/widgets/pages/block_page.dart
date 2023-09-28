import 'package:blockchain/blockchain.dart';
import 'package:blockchain/data_stores.dart';
import 'package:blockchain_app/widgets/bitmap_render.dart';
import 'package:blockchain_codecs/codecs.dart';
import 'package:blockchain_common/utils.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class UnloadedBlockPage extends StatelessWidget {
  final BlockId id;

  const UnloadedBlockPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _load(context.watch<Blockchain>().dataStores),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data != null) {
              return BlockPage(block: snapshot.data!);
            } else {
              return _scaffold(notFound);
            }
          } else {
            return _scaffold(loading);
          }
        });
  }

  Future<FullBlock?> _load(DataStores dataStores) async {
    final header = await dataStores.headers.getOrRaise(id);
    final body = await dataStores.bodies.getOrRaise(id);
    final transactions = await Future.wait(
        body.transactionIds.map(dataStores.transactions.getOrRaise));
    final fullBody = FullBlockBody()..transactions.addAll(transactions);
    return FullBlock()
      ..header = header
      ..fullBody = fullBody;
  }

  _scaffold(Widget body) =>
      Scaffold(appBar: AppBar(title: const Text("Block View")), body: body);

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
  Widget build(BuildContext context) => Scaffold(
        appBar: _appBar,
        body: _body(context),
      );

  get _appBar => AppBar(
        title: const Text("Block View"),
      );

  _body(BuildContext context) => _paddedCard(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _blockIdCard(),
            _blockMetadataCard(context),
            Expanded(child: _transactionsCard(context)),
          ],
        ),
      );

  Card _paddedCard(Widget child) => Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: child,
        ),
      );

  Card _blockIdCard() {
    return _paddedCard(
      Row(
        children: [
          SizedBox.square(
              dimension: 64, child: BitMapViewer.forBlock(block.header.id)),
          _overUnderWidgets(
            const Text("Block ID",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                )),
            Text(
              block.header.id.show,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.blueGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Card _blockMetadataCard(BuildContext context) {
    return _paddedCard(
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _paddedCard(_overUnder("Height", block.header.height.toString())),
          _paddedCard(_overUnder("Slot", block.header.slot.toString())),
          _paddedCard(_overUnder(
            "Timestamp",
            DateFormat().format(_headerDateTime()),
          )),
          _paddedCard(StreamBuilder(
            stream: Stream.periodic(const Duration(seconds: 1)),
            builder: (context, snapshot) => _overUnder(
              "Minted",
              GetTimeAgo.parse(_headerDateTime()),
            ),
          )),
          _paddedCard(_overUnderWidgets(
              const Text("Parent"),
              block.header.height > 1
                  ? _parentLink(context)
                  : const Icon(Icons.account_tree))),
        ],
      ),
    );
  }

  _parentLink(BuildContext context) {
    return OutlinedButton(
        onPressed: () => FluroRouter.appRouter
            .navigateTo(context, "/blocks/${block.header.parentHeaderId.show}"),
        child: SizedBox.square(
            dimension: 32,
            child: BitMapViewer.forBlock(block.header.parentHeaderId)));
  }

  Card _transactionsCard(BuildContext context) {
    return _paddedCard(Column(children: [
      _overUnderWidgets(
          const Text(
            "Transactions",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          DataTable(
            columns: const [
              DataColumn(label: Text("ID")),
              DataColumn(label: Text("In")),
              DataColumn(label: Text("Out")),
              DataColumn(label: Text("Tip")),
            ],
            rows: block.fullBody.transactions
                .map((t) => DataRow(cells: [
                      DataCell(TextButton(
                        child: SizedBox.square(
                            dimension: 32,
                            child: BitMapViewer.forTransaction(t.id)),
                        onPressed: () => FluroRouter.appRouter
                            .navigateTo(context, "/transactions/${t.id.show}"),
                      )),
                      DataCell(Text(t.inputSum.toString())),
                      DataCell(Text(t.outputSum.toString())),
                      DataCell(Text(t.reward.toString())),
                    ]))
                .toList(),
          ))
    ]));
  }

  DateTime _headerDateTime() {
    return DateTime.fromMillisecondsSinceEpoch(block.header.timestamp.toInt());
  }

  static const TextStyle _defaultOverStyle =
      TextStyle(fontWeight: FontWeight.bold);
  static const TextStyle _defaultUnderStyle = TextStyle(color: Colors.blueGrey);

  Widget _overUnder(String overText, String underText) => _overUnderWidgets(
        Text(overText, style: _defaultOverStyle),
        Text(underText, style: _defaultUnderStyle),
      );

  Widget _overUnderWidgets(Widget over, Widget under) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            over,
            const Divider(),
            under,
          ],
        ),
      );
}
