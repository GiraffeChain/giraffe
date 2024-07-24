import 'dart:async';

import 'package:async/async.dart';
import 'package:blockchain_app/widgets/pages/blockchain_launcher_page.dart';
import 'package:blockchain_app/widgets/pages/genesis_builder_page.dart';
import 'package:blockchain_app/widgets/pages/stake_page.dart';
import 'package:blockchain_app/widgets/pages/transact_page.dart';
import 'package:blockchain/codecs.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:fixnum/fixnum.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BlockchainPage extends StatelessWidget {
  const BlockchainPage({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 4,
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
      Tab(icon: Icon(Icons.publish), child: Text("Stake")),
      Tab(
          icon: Icon(Icons.baby_changing_station),
          child: Text("Genesis Builder")),
    ]);
  }

  _tabBarView(BuildContext context) {
    final blockchain = context.watch<BlockchainView>();
    final blockchainWriter = context.watch<BlockchainWriter>();
    return TabBarView(children: [
      const LiveBlocksView(),
      StreamedTransactView(view: blockchain, writer: blockchainWriter),
      StakeView(view: blockchain, writer: blockchainWriter),
      const GenesisBuilderView(),
    ]);
  }

  static const _metadataTextStyle =
      TextStyle(fontSize: 12, fontWeight: FontWeight.bold);

  AppBar _appBar(BuildContext context) {
    final slotTicker = _slotText(context);
    return AppBar(
      title: StreamBuilder(
        stream: context
            .watch<BlockchainView>()
            .adoptedBlocks
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

  _slotText(BuildContext context) {
    final blockchain = context.watch<BlockchainView>();
    return StreamBuilder<Int64>(
        stream: Stream.fromFuture(blockchain.genesisBlock)
            .map((b) => (
                  b.header.timestamp,
                  Int64(ProtocolSettings.defaultSettings
                      .mergeFromMap(b.header.settings)
                      .slotDuration
                      .inMilliseconds)
                ))
            .asyncExpand((t) => Stream.periodic(const Duration(seconds: 1)).map(
                (_) =>
                    (Int64(DateTime.now().millisecondsSinceEpoch) - t.$1) ~/
                    t.$2)),
        builder: (context, snapshot) => Row(children: [
              const VerticalDivider(),
              Text("Slot: ${snapshot.data ?? Int64.ZERO}",
                  style: _metadataTextStyle),
            ]));
  }
}

class LatestBlockView extends StatelessWidget {
  final BlockchainView blockchain;

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

class LiveBlocksView extends StatefulWidget {
  const LiveBlocksView({super.key});

  @override
  State<StatefulWidget> createState() => LiveBlocksViewState();
}

class LiveBlocksViewState extends State<StatefulWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: StreamBuilder(
        stream: _accumulateBlocksStream(context),
        builder: (context, snapshot) => _blocksView(snapshot.data ?? []),
      ),
    );
  }

  Stream<List<FullBlock>> _accumulateBlocksStream(BuildContext context) =>
      _fullBlocks(context.read<BlockchainView>())
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

  @override
  bool get wantKeepAlive => true;
}

Stream<FullBlock> _fullBlocks(BlockchainView blockchain) => StreamGroup.merge([
      Stream.fromFuture(blockchain.canonicalHeadId),
      blockchain.adoptions
    ]).asyncMap((id) async {
      final header = await blockchain.getBlockHeaderOrRaise(id);
      final body = await blockchain.getBlockBodyOrRaise(id);
      final transactions = await Future.wait(
          body.transactionIds.map(blockchain.getTransactionOrRaise));
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
