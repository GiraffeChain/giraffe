import 'dart:async';

import 'package:async/async.dart';
import 'package:blockchain_app/providers/blockchain_reader_writer.dart';
import 'package:blockchain_app/widgets/pages/genesis_builder_page.dart';
import 'package:blockchain_app/widgets/pages/receive_page.dart';
import 'package:blockchain_app/widgets/pages/stake_page.dart';
import 'package:blockchain_app/widgets/pages/transact_page.dart';
import '../../blockchain/codecs.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:fixnum/fixnum.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlockchainPage extends ConsumerWidget {
  const BlockchainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readerWriter = ref.watch(podBlockchainReaderWriterProvider);
    return DefaultTabController(
      length: 5,
      child: Scaffold(
          appBar: _appBar(context, readerWriter),
          body: Container(
              constraints: const BoxConstraints.expand(),
              child: _tabBarView(context, readerWriter))),
    );
  }

  _tabBar(BuildContext context) {
    return const TabBar(tabs: [
      Tab(icon: Icon(Icons.square_outlined), child: Text("Chain")),
      Tab(icon: Icon(Icons.send), child: Text("Send")),
      Tab(icon: Icon(Icons.wallet), child: Text("Receive")),
      Tab(icon: Icon(Icons.publish), child: Text("Stake")),
      Tab(
          icon: Icon(Icons.baby_changing_station),
          child: Text("Genesis Builder")),
    ]);
  }

  _tabBarView(BuildContext context, BlockchainReaderWriter readerWriter) {
    return TabBarView(children: [
      LiveBlocksView(view: readerWriter.view),
      StreamedTransactView(
          view: readerWriter.view, writer: readerWriter.writer),
      const ReceiveView(),
      StakeView(view: readerWriter.view, writer: readerWriter.writer),
      const GenesisBuilderView(),
    ]);
  }

  static const _metadataTextStyle =
      TextStyle(fontSize: 12, fontWeight: FontWeight.bold);

  AppBar _appBar(BuildContext context, BlockchainReaderWriter readerWriter) {
    final slotTicker = _slotText(context, readerWriter);
    return AppBar(
      title: StreamBuilder(
        stream: readerWriter.view.adoptedBlocks
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

  _slotText(BuildContext context, BlockchainReaderWriter readerWriter) =>
      StreamBuilder<Int64>(
          stream: Stream.fromFuture(readerWriter.view.genesisBlock)
              .map((b) => (
                    b.header.timestamp,
                    Int64(ProtocolSettings.defaultSettings
                        .mergeFromMap(b.header.settings)
                        .slotDuration
                        .inMilliseconds)
                  ))
              .asyncExpand((t) => Stream.periodic(const Duration(seconds: 1))
                  .map((_) =>
                      (Int64(DateTime.now().millisecondsSinceEpoch) - t.$1) ~/
                      t.$2)),
          builder: (context, snapshot) => Row(children: [
                const VerticalDivider(),
                Text("Slot: ${snapshot.data ?? Int64.ZERO}",
                    style: _metadataTextStyle),
              ]));
}

class LiveBlocksView extends StatelessWidget {
  final BlockchainView view;

  const LiveBlocksView({super.key, required this.view});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: StreamBuilder(
        stream: _accumulateBlocksStream(context),
        builder: (context, snapshot) => _blocksView(snapshot.data ?? []),
      ),
    );
  }

  Stream<List<FullBlock>> _accumulateBlocksStream(BuildContext context) =>
      _fullBlocks.transform(StreamTransformer.fromBind((inStream) {
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

  Stream<FullBlock> get _fullBlocks => StreamGroup.merge(
          [Stream.fromFuture(view.canonicalHeadId), view.adoptions])
      .asyncMap(view.getFullBlockOrRaise);
}

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
