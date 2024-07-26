import 'dart:convert';
import 'dart:io';

import 'package:blockchain/private_testnet.dart';
import 'package:blockchain/staking_account.dart';
import 'package:blockchain_app/providers/blockchain_reader_writer.dart';
import 'package:blockchain_app/providers/staking.dart';
import 'package:blockchain_app/providers/storage.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

class StakeView extends ConsumerStatefulWidget {
  final BlockchainView view;
  final BlockchainWriter writer;

  const StakeView({super.key, required this.view, required this.writer});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => StakeViewState();
}

class StakeViewState extends ConsumerState<StakeView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(podStakingProvider);
    if (state.minting != null) {
      return RunMinting(viewer: widget.view, writer: widget.writer);
    } else {
      return FutureBuilder(
          future: stakingIsInitialized(ref.watch(podSecureStorageProvider))
              .then((v) {
            if (v) {
              ref.read(podStakingProvider.notifier).initMinting();
            }
            return v;
          }),
          builder: (context, snapshot) => snapshot.hasData
              ? (snapshot.data!
                  ? RunMinting(viewer: widget.view, writer: widget.writer)
                  : noStaker)
              : snapshot.hasError
                  ? Center(child: Text("An error occurred: ${snapshot.error}"))
                  : loading);
    }
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
              onChanged: (index) => _onTestnetStakerSelected(index ?? 0)),
        ],
      ));

  Future<void> _onTestnetStakerSelected(int index) async {
    final genesis = await widget.view.genesisBlock;
    final genesisTimestamp = genesis.header.timestamp;
    final seed = [...genesisTimestamp.immutableBytes, ...index.immutableBytes];
    final stakerInitializer = await StakingAccount.generate(
        ProtocolSettings.defaultSettings.kesTreeHeight,
        Int64(10000000),
        await PrivateTestnet.DefaultLockAddress,
        seed);
    final stakingAddress =
        StakingAddress(value: stakerInitializer.operatorVk.base58);
    final accountTx = genesis.fullBody.transactions.firstWhere((tx) => tx
        .outputs
        .where((o) =>
            o.value.hasAccountRegistration() &&
            o.value.accountRegistration.stakingRegistration.stakingAddress ==
                stakingAddress)
        .isNotEmpty);
    final account =
        TransactionOutputReference(transactionId: accountTx.id, index: 0);
    final secureStorage = ref.read(podSecureStorageProvider);
    await secureStorage.write(
        key: "blockchain-staker-vrf-sk",
        value: base64.encode(stakerInitializer.vrfSk));
    await secureStorage.write(
        key: "blockchain-staker-account",
        value: base64.encode(account.writeToBuffer()));
    await secureStorage.write(
        key: "blockchain-staker-kes",
        value: base64.encode(stakerInitializer.kesSk.encode));
    setState(() {});
  }

  Future<void> _onDirectorySelected(BuildContext context, String path) async {
    final dir = Directory(path);
    final isStaking = await directoryContainsStakingFiles(dir);
    if (isStaking) {
      final secureStorage = ref.read(podSecureStorageProvider);
      secureStorage.write(
          key: "blockchain-staker-vrf-sk",
          value: base64.encode(await File("${dir.path}/vrf").readAsBytes()));
      secureStorage.write(
          key: "blockchain-staker-account",
          value:
              base64.encode(await File("${dir.path}/account").readAsBytes()));
      secureStorage.write(
          key: "blockchain-staker-kes",
          value: base64.encode(await File("${dir.path}/kes").readAsBytes()));
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid staking directory selected")));
    }
  }
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

class RunMinting extends ConsumerWidget {
  final BlockchainView viewer;
  final BlockchainWriter writer;

  const RunMinting({super.key, required this.viewer, required this.writer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stopFunction = ref.watch(podStakingProvider).stop;
    return Card(
      child: Column(children: [
        TextButton.icon(
          onPressed: () => ref.read(podStakingProvider.notifier).reset(),
          label: const Text("Delete Staker"),
          icon: const Icon(Icons.delete),
        ),
        stopFunction == null
            ? TextButton.icon(
                onPressed: () => ref.read(podStakingProvider.notifier).start(),
                label: const Text("Start"),
                icon: const Icon(Icons.play_arrow))
            : TextButton.icon(
                onPressed: () => stopFunction(),
                label: const Text("Stop"),
                icon: const Icon(Icons.stop),
              ),
      ]),
    );
  }

  static final log = Logger("MintingWidget");
}

Future<bool> stakingIsInitialized(FlutterSecureStorage storage) async =>
    await storage.containsKey(key: "blockchain-staker-vrf-sk") &&
    await storage.containsKey(key: "blockchain-staker-account") &&
    await storage.containsKey(key: "blockchain-staker-kes");

Future<bool> directoryContainsStakingFiles(Directory dir) async =>
    (await File("${dir.path}/vrf").exists()) &&
    (await File("${dir.path}/operator").exists()) &&
    (await File("${dir.path}/account").exists()) &&
    (await File("${dir.path}/kes").exists());
