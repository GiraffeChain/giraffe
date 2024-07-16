import 'dart:io';

import 'package:blockchain/blockchain_view.dart';
import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/clock.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain/consensus/leader_election_validation.dart';
import 'package:blockchain/crypto/kes.dart';
import 'package:blockchain/crypto/utils.dart';
import 'package:blockchain/data_stores.dart';
import 'package:blockchain/minting/minting.dart';
import 'package:blockchain/staker_initializer.dart';
import 'package:blockchain_app/widgets/pages/blockchain_launcher_page.dart';
import 'package:blockchain_app/widgets/resource_builder.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_protobuf/services/staker_support_rpc.pb.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ribs_effect/ribs_effect.dart';

class StakeView extends StatefulWidget {
  final BlockchainView view;
  final BlockchainWriter writer;

  const StakeView({super.key, required this.view, required this.writer});

  @override
  State<StatefulWidget> createState() => StakeViewState();
}

class StakeViewState extends State<StakeView>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
        future: stakingIsInitialized,
        builder: (context, snapshot) => snapshot.hasData
            ? (snapshot.data!
                ? RunMinting(viewer: widget.view, writer: widget.writer)
                : noStaker)
            : snapshot.hasError
                ? Center(child: Text("An error occurred: ${snapshot.error}"))
                : loading);
  }

  Widget get loading =>
      const Card(child: Center(child: CircularProgressIndicator()));

  Widget get noStaker => Card(
          child: Column(
        children: [
          const Text("No staker is available."),
          const Text(
              "Please register a new account or import from a different directory."),
          DirectoryChooser(
              onDirectorySelected: (path) =>
                  _onDirectorySelected(context, path)),
          const Text(
              "Alternatively, if this is a testnet, select the desired staker index (0, 1, 2, etc.)."),
          DropdownButton<int>(
              items: const [DropdownMenuItem(value: 0, child: Text("0"))],
              onChanged: (index) =>
                  _onTestnetStakerSelected(context, index ?? 0)),
        ],
      ));

  Future<void> _onTestnetStakerSelected(BuildContext context, int index) async {
    final genesis = await widget.view.genesisBlock;
    final stakingDir = await (await stakingDirectory).create(recursive: true);
    final genesisTimestamp = genesis.header.timestamp;
    final seed = [...genesisTimestamp.immutableBytes, ...index.immutableBytes];
    final stakerInitializer =
        await StakerInitializer.fromSeed(seed, TreeHeight(9, 9));
    final stakingAddress =
        StakingAddress(value: stakerInitializer.operatorKeyPair.vk.base58);
    final accountTx = genesis.fullBody.transactions.firstWhere((tx) => tx
        .outputs
        .where((o) =>
            o.value.hasAccountRegistration() &&
            o.value.accountRegistration.stakingRegistration.stakingAddress ==
                stakingAddress)
        .isNotEmpty);
    final account =
        TransactionOutputReference(transactionId: accountTx.id, index: 0);
    await stakerInitializer.save(stakingDir);
    await File("${stakingDir.path}/account")
        .writeAsBytes(account.writeToBuffer());
    setState(() {});
  }

  Future<void> _onDirectorySelected(BuildContext context, String path) async {
    final dir = Directory(path);
    final isStaking = await directoryContainsStakingFiles(dir);
    if (isStaking) {
      final stakingDir = await (await stakingDirectory).create(recursive: true);
      copy(String a) => File("${dir.path}/$a").copy("${stakingDir.path}/$a");
      await copy("vrf");
      await copy("operator");
      await copy("account");
      await copy("kes");
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid staking directory selected")));
    }
  }

  @override
  final wantKeepAlive = true;
}

class DirectoryChooser extends StatefulWidget {
  final void Function(String) onDirectorySelected;

  const DirectoryChooser({super.key, required this.onDirectorySelected});

  @override
  State<StatefulWidget> createState() => DirectoryChooserState();
}

class DirectoryChooserState extends State<DirectoryChooser> {
  String _value = "";

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: 500,
      child: Row(
        children: [
          Expanded(child: TextFormField(onChanged: (str) => _value = str)),
          TextButton.icon(
              onPressed: () => widget.onDirectorySelected(_value),
              icon: const Icon(Icons.copy_all),
              label: const Text("Import"))
        ],
      ),
    );
  }
}

class RunMinting extends StatefulWidget {
  final BlockchainView viewer;
  final BlockchainWriter writer;

  const RunMinting({super.key, required this.viewer, required this.writer});

  @override
  State<StatefulWidget> createState() => RunMintingState();
}

class RunMintingState extends State<RunMinting> {
  bool paused = true;

  @override
  Widget build(BuildContext context) => Card(
          child: Center(
        child: paused
            ? launchButton
            : ResourceBuilder(
                resource: resource,
                builder: (context, snapshot) => IconButton(
                    onPressed: () => setState(() => paused = true),
                    icon: const Icon(Icons.pause)),
              ),
      ));

  final log = Logger("MintingWidget");

  Resource get resource => Resource.pure(()).evalFlatMap((_) async {
        final viewer = widget.viewer;
        final canonicalHeadId = await viewer.canonicalHeadId;
        final canonicalHead =
            await viewer.getBlockHeaderOrRaise(canonicalHeadId);
        log.info(
            "Canonical head id=${canonicalHeadId.show} height=${canonicalHead.height} slot=${canonicalHead.slot}");
        final protocolSettings = await viewer.protocolSettings;

        final genesisBlockId = await viewer.genesisBlockId;
        final genesisHeader =
            await viewer.getBlockHeaderOrRaise(genesisBlockId);
        log.info(
            "Genesis id=${genesisBlockId.show} height=${genesisHeader.height} slot=${genesisHeader.slot}");
        final stakerSupportClient = widget.writer.stakerClient;
        final clock = ClockImpl(
          protocolSettings.slotDuration,
          protocolSettings.epochLength,
          protocolSettings.operationalPeriodLength,
          genesisHeader.timestamp,
        );
        final leaderElection = LeaderElectionImpl(protocolSettings, isolate);
        final stakingDir = await stakingDirectory;
        return Minting.makeForRpc(
          Directory(
              DataStores.interpolateBlockId(stakingDir.path, genesisBlockId)),
          protocolSettings,
          clock,
          canonicalHead,
          viewer.adoptions.map((id) {
            log.info("Remote peer adopted block id=${id.show}");
            return id;
          }).asyncMap(viewer.getBlockHeaderOrRaise),
          leaderElection,
          viewer,
          stakerSupportClient,
          null, // TODO
        ).flatMap((minting) => ResourceUtils.forStreamSubscription(() => minting
            .blockProducer.blocks
            .asyncMap((block) => stakerSupportClient
                .broadcastBlock(BroadcastBlockReq(
                    block: Block(
                        header: block.header,
                        body: BlockBody(
                            transactionIds:
                                block.fullBody.transactions.map((t) => t.id)))))
                .then((_) => block))
            .listen(
              (block) => log.info(
                  "Successfully broadcasted block id=${block.header.id.show}"),
              onError: (e, s) => log.severe("Production failed", e, s),
              onDone: () => log.info("Block production finished unexpectedly"),
            )));
      });

  Widget get launchButton => TextButton.icon(
      onPressed: () => setState(() => paused = false),
      icon: const Icon(Icons.play_arrow),
      label: const Text("Launch"));
}

Future<Directory> get stakingDirectory async => Directory(
    "${(await getApplicationDocumentsDirectory()).path}/blockchain/staking");

Future<bool> get stakingIsInitialized async =>
    directoryContainsStakingFiles(await stakingDirectory);

Future<bool> directoryContainsStakingFiles(Directory dir) async =>
    (await File("${dir.path}/vrf").exists()) &&
    (await File("${dir.path}/operator").exists()) &&
    (await File("${dir.path}/account").exists()) &&
    (await File("${dir.path}/kes").exists());
