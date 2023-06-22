import 'dart:async';

import 'package:async/async.dart';
import 'package:blockchain/blockchain.dart';
import 'package:blockchain_app/widgets/transact.dart';
import 'package:blockchain_codecs/codecs.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:im_animations/im_animations.dart';

class BlockchainPage extends StatefulWidget {
  final Blockchain blockchain;

  const BlockchainPage({super.key, required this.blockchain});

  @override
  State<StatefulWidget> createState() => _BlockchainPageState();
}

class _BlockchainPageState extends State<BlockchainPage> {
  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
            appBar: _appBar(context),
            body: Container(
                constraints: const BoxConstraints.expand(),
                decoration: const BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("assets/images/fractal7.png"),
                        fit: BoxFit.none)),
                child: _tabBarView(context))),
      );

  _tabBar(BuildContext context) {
    return const TabBar(tabs: [
      Tab(icon: Icon(Icons.square_outlined)),
      Tab(icon: Icon(Icons.wallet))
    ]);
  }

  _tabBarView(BuildContext context) {
    return TabBarView(children: [
      LatestBlockView(blockchain: widget.blockchain),
      Expanded(child: TransactView())
    ]);
  }

  static const _metadataTextStyle =
      TextStyle(fontSize: 12, fontWeight: FontWeight.bold);

  AppBar _appBar(BuildContext context) {
    final slotTicker = _slotText;
    return AppBar(
      title: StreamBuilder(
        stream: widget.blockchain.newBlocks
            .map((b) => b.header)
            .asyncMap((header) async => [
                  const VerticalDivider(),
                  Text((await header.id).show, style: _metadataTextStyle),
                  const VerticalDivider(),
                  Text("Height: ${header.height}", style: _metadataTextStyle)
                ]),
        builder: (context, snapshot) => Row(children: <Widget>[
          const Text("Blockchain"),
          ...?snapshot.data,
          slotTicker
        ]),
      ),
      bottom: _tabBar(context),
    );
  }

  get _slotText => StreamBuilder(
      stream: widget.blockchain.clock.slots,
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
  final Blockchain blockchain;

  const LiveBlocksView({super.key, required this.blockchain});
  @override
  Widget build(BuildContext context) => Center(
        child: StreamBuilder(
          stream: _accumulateBlocksStream,
          builder: (context, snapshot) => _blocksView(snapshot.data ?? []),
        ),
      );

  Stream<List<FullBlock>> get _accumulateBlocksStream =>
      _fullBlocks(blockchain).transform(StreamTransformer.fromBind((inStream) {
        final List<FullBlock> state = [];
        return inStream.map((block) {
          state.insert(0, block);
          return List.of(state);
        });
      }));

  Widget _blocksView(List<FullBlock> blocks) => ColorSonar(
        contentAreaRadius: 480,
        child: SizedBox(
          width: 500,
          child: ListView.separated(
            itemCount: blocks.length,
            itemBuilder: (context, index) => BlockCard(block: blocks[index]),
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(),
          ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder(
                future: block.header.id,
                builder: (context, snapshot) =>
                    Text(snapshot.data?.show ?? "")),
            Text("Height: ${block.header.height}"),
            Text("Slot: ${block.header.slot}"),
            Text("Timestamp: ${block.header.timestamp}"),
            Text("Transactions: ${block.fullBody.transactions.length}"),
          ],
        ),
      ),
    );
  }
}
