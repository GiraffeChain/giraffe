import 'dart:async';

import 'package:async/async.dart';
import 'package:blockchain/blockchain.dart';
import 'package:blockchain_codecs/codecs.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:flutter/material.dart';
import 'package:im_animations/im_animations.dart';

class TransactView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => TransactViewState();
}

class TransactViewState extends State<TransactView> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ExpansionPanelList(children: [
        ExpansionPanel(
            headerBuilder: (context, isExpanded) => const Text("Inputs"),
            body: const Text("TODO")),
        ExpansionPanel(
            headerBuilder: (context, isExpanded) => const Text("Outputs"),
            body: const Text("TODO")),
        ExpansionPanel(
            headerBuilder: (context, isExpanded) => const Text("Schedule"),
            body: const Text("TODO")),
      ]),
    );
  }
}
