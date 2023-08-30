import 'package:blockchain_codecs/codecs.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:intl/intl.dart';

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

  _body(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FutureBuilder(
                      future: block.header.id,
                      builder: (context, snapshot) =>
                          _overUnder("Block ID", snapshot.data?.show ?? "")),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _overUnder("Height", block.header.height.toString()),
                      _overUnder("Slot", block.header.slot.toString()),
                      _overUnder(
                        "Timestamp",
                        DateFormat().format(DateTime.fromMillisecondsSinceEpoch(
                            block.header.timestamp.toInt())),
                      ),
                      StreamBuilder(
                        stream: Stream.periodic(const Duration(seconds: 1)),
                        builder: (context, snapshot) => _overUnder(
                          "Minted",
                          GetTimeAgo.parse(DateTime.fromMillisecondsSinceEpoch(
                              block.header.timestamp.toInt())),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _overUnder(String overText, String underText) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              overText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const VerticalDivider(
              thickness: 4,
            ),
            Text(underText, style: const TextStyle(color: Colors.blueGrey)),
          ],
        ),
      );
}
