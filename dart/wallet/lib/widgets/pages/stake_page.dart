import '../../providers/staking/block_production.dart';
import '../../providers/staking/staking.dart';
import '../../providers/storage.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

class StakeView extends ConsumerStatefulWidget {
  final BlockchainClient client;

  const StakeView({super.key, required this.client});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => StakeViewState();
}

class StakeViewState extends ConsumerState<StakeView> {
  bool advancedMode = false;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(podStakingProvider);
    if (state != null) {
      return RunMinting(client: widget.client);
    } else if (advancedMode) {
      return advancedModeCard;
    } else {
      return FutureBuilder(
          future: stakingIsInitialized(ref.watch(podSecureStorageProvider))
              .then((v) async {
            if (v) {
              await ref.read(podStakingProvider.notifier).initMinting();
            }
            return v;
          }),
          builder: (context, snapshot) => snapshot.hasData
              ? (snapshot.data! ? RunMinting(client: widget.client) : noStaker)
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
          const Text(
              "Help improve the network by staking your tokens, and earn rewards in the process!"),
          const Text("To begin, register a new account."),
          registerButton(context),
          IconButton(
              icon: const Icon(Icons.warning),
              onPressed: () => setState(() => advancedMode = true)),
        ],
      ));

  Widget get advancedModeCard => Card(
          child: Column(
        children: [
          const Text(
              "This area is for developers/testers only. Please be careful!"),
          const Text("Import your keys from a local directory"),
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
    await ref.read(podStakingProvider.notifier).initMintingTestnet(index);
  }

  Future<void> _onDirectorySelected(BuildContext context, String path) async {
    try {
      await ref
          .read(podStakingProvider.notifier)
          .initMintingFromDirectory(path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid staking directory selected.")));
    }
  }

  Widget registerButton(BuildContext context) => TextButton.icon(
      onPressed: () => ref.read(podStakingProvider.notifier).register(),
      label: const Text("Register"),
      icon: const Icon(Icons.app_registration_rounded));
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
  final BlockchainClient client;

  const RunMinting({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final production = ref.watch(podBlockProductionProvider);
    Future<void> Function()? stopFunction;
    if (production is ActivePodBlockProductionState) {
      stopFunction = production.stop;
    }
    return Card(
      child: Column(children: [
        TextButton.icon(
          onPressed: () => ref.read(podStakingProvider.notifier).reset(),
          label: const Text("Delete Staker"),
          icon: const Icon(Icons.delete),
        ),
        stopFunction != null
            ? TextButton.icon(
                onPressed: () => stopFunction!(),
                label: const Text("Stop"),
                icon: const Icon(Icons.stop),
              )
            : TextButton.icon(
                onPressed: () =>
                    ref.read(podBlockProductionProvider.notifier).start(),
                label: const Text("Start"),
                icon: const Icon(Icons.play_arrow)),
      ]),
    );
  }

  static final log = Logger("MintingWidget");
}

Future<bool> stakingIsInitialized(FlutterSecureStorage storage) async =>
    await storage.containsKey(key: "blockchain-staker-vrf-sk") &&
    await storage.containsKey(key: "blockchain-staker-account") &&
    await storage.containsKey(key: "blockchain-staker-operator-sk");
