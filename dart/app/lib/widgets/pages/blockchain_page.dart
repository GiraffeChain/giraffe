import 'dart:async';

import 'package:async/async.dart';
import 'package:blockchain/blockchain.dart';
import 'package:blockchain_app/widgets/pages/transact_page.dart';
import 'package:blockchain_codecs/codecs.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class BlockchainPage extends StatelessWidget {
  const BlockchainPage({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
            appBar: _appBar(context),
            body: Container(
                constraints: const BoxConstraints.expand(),
                child: _tabBarView(context))),
      );

  _tabBar(BuildContext context) {
    return const TabBar(tabs: [
      Tab(icon: Icon(Icons.square_outlined), child: Text("Chain")),
      Tab(icon: Icon(Icons.send), child: Text("Send")),
    ]);
  }

  _tabBarView(BuildContext context) {
    final blockchain = context.watch<Blockchain>();
    return TabBarView(children: [
      const LiveBlocksView(),
      StreamBuilder(
        stream: Stream.fromFuture(blockchain.localChain.currentHead)
            .concatWith([blockchain.localChain.adoptions]).asyncMap(
                (id) => blockchain.walletESS.stateAt(id)),
        builder: (context, snapshot) => snapshot.hasData
            ? TransactView(
                wallet: snapshot.data!,
                processTransaction: (tx) async {
                  await blockchain.dataStores.transactions.put(tx.id, tx);
                  await blockchain.mempool.add(tx.id);
                },
              )
            : const CircularProgressIndicator(),
      )
    ]);
  }

  static const _metadataTextStyle =
      TextStyle(fontSize: 12, fontWeight: FontWeight.bold);

  AppBar _appBar(BuildContext context) {
    final slotTicker = _slotText(context);
    return AppBar(
      title: StreamBuilder(
        stream: context
            .watch<Blockchain>()
            .newBlocks
            .map((b) => b.header)
            .asyncMap((header) async => [
                  const VerticalDivider(),
                  Text((header.id).show, style: _metadataTextStyle),
                  const VerticalDivider(),
                  Text("Height: ${header.height}", style: _metadataTextStyle)
                ]),
        builder: (context, snapshot) => Row(children: <Widget>[
          slotTicker,
          ...?snapshot.data,
        ]),
      ),
      bottom: _tabBar(context),
    );
  }

  _slotText(BuildContext context) => StreamBuilder(
      stream: context.watch<Blockchain>().clock.slots,
      builder: (context, snapshot) => Row(children: [
            const VerticalDivider(),
            Text("Slot: ${snapshot.data ?? Int64.ZERO}",
                style: _metadataTextStyle),
          ]));
}

class LatestBlockView extends StatelessWidget {
  final Blockchain blockchain;

  const LatestBlockView({super.key, required this.blockchain});
  @override
  Widget build(BuildContext context) => Center(
        child: StreamBuilder(
          stream: _fullBlocks(blockchain),
          builder: (context, snapshot) => snapshot.data != null
              ? _card(snapshot.data!)
              : const CircularProgressIndicator(),
        ),
      );

  Widget _card(FullBlock block) => BlockCard(
        block: block,
      );
}

class LiveBlocksView extends StatelessWidget {
  const LiveBlocksView({super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: StreamBuilder(
          stream: _accumulateBlocksStream(context),
          builder: (context, snapshot) => _blocksView(snapshot.data ?? []),
        ),
      );

  Stream<List<FullBlock>> _accumulateBlocksStream(BuildContext context) =>
      _fullBlocks(context.read<Blockchain>())
          .transform(StreamTransformer.fromBind((inStream) {
        final List<FullBlock> state = [];
        return inStream.map((block) {
          state.insert(0, block);
          return List.of(state);
        });
      }));

  Widget _blocksView(List<FullBlock> blocks) => SizedBox(
        width: 500,
        child: ListView.separated(
          itemCount: blocks.length,
          itemBuilder: (context, index) => BlockCard(block: blocks[index]),
          separatorBuilder: (BuildContext context, int index) =>
              const Divider(),
        ),
      );
}

Stream<FullBlock> _fullBlocks(Blockchain blockchain) => StreamGroup.merge([
      Stream.fromFuture(blockchain.localChain.currentHead),
      blockchain.localChain.adoptions
    ]).asyncMap((id) async {
      final header = await blockchain.dataStores.headers.getOrRaise(id);
      final body = await blockchain.dataStores.bodies.getOrRaise(id);
      final transactions = await Future.wait(body.transactionIds
          .map(blockchain.dataStores.transactions.getOrRaise));
      final fullBlock = FullBlock()
        ..header = header
        ..fullBody = (FullBlockBody()..transactions.addAll(transactions));
      return fullBlock;
    });

class BlockCard extends StatelessWidget {
  final FullBlock block;

  const BlockCard({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FluroRouter.appRouter
          .navigateTo(context, "/blocks/${block.header.id.show}"),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(block.header.id.show),
              Text("Height: ${block.header.height}"),
              Text("Slot: ${block.header.slot}"),
              Text("Timestamp: ${block.header.timestamp}"),
              Text("Transactions: ${block.fullBody.transactions.length}"),
            ],
          ),
        ),
      ),
    );
  }
}
