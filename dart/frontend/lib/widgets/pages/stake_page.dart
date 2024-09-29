import 'package:fixnum/fixnum.dart';
import 'package:giraffe_frontend/blockchain/minting/models/staker_data.dart';
import 'package:giraffe_frontend/providers/wallet.dart';
import 'package:giraffe_frontend/utils.dart';
import 'package:giraffe_frontend/widgets/giraffe_scaffold.dart';

import '../../providers/blockchain_client.dart';
import '../../providers/staking/block_production.dart';
import '../../providers/staking/staking.dart';
import '../../providers/storage.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

import '../giraffe_card.dart';

class StakeView extends ConsumerWidget {
  const StakeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GiraffeScaffold(
      title: "Stake",
      body: GiraffeCard(
        child: body(context, ref),
      ).pad16,
    );
  }

  Widget body(BuildContext context, WidgetRef ref) {
    final client = ref.watch(podBlockchainClientProvider);
    if (client == null) {
      return const Center(child: Text("Not initialized"));
    }
    switch (ref.watch(podStakingProvider)) {
      case AsyncLoading():
        return const Center(child: CircularProgressIndicator());
      case AsyncError(:final error):
        return errorWidget(error);
      case AsyncValue(:final value):
        if (value != null) {
          return RunMinting(client: client);
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
                  ? (snapshot.data!
                      ? RunMinting(client: client)
                      : const StakingNotConfigured())
                  : snapshot.hasError
                      ? errorWidget(snapshot.error)
                      : loading);
        }
    }
  }

  Widget get loading => const Center(child: CircularProgressIndicator());

  Widget errorWidget(Object? message) =>
      Center(child: Text("An error occurred: $message"));
}

class StakingNotConfigured extends ConsumerStatefulWidget {
  const StakingNotConfigured({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      StakingNotConfiguredState();
}

class StakingNotConfiguredState extends ConsumerState<StakingNotConfigured> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "Staking and Block Production",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ).pad8,
        const Text(
          "Help improve the network by staking your tokens, and earn rewards in the process!",
          style: TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ).pad8,
        const Text(
          "To begin, register a new account.",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        registerButton(context),
        const Text(
          "Alternatively, you can import from a backup.",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        ImportStaker(
            onImported: (data) =>
                ref.read(podStakingProvider.notifier).initFromStakerData(data)),
      ].padAll16,
    );
  }

  Widget registerButton(BuildContext context) => TextButton.icon(
      onPressed: () => ref.read(podStakingProvider.notifier).register(),
      label: const Text("Register"),
      icon: const Icon(Icons.app_registration_rounded));
}

class ImportStaker extends StatefulWidget {
  final void Function(StakerData) onImported;

  const ImportStaker({super.key, required this.onImported});

  @override
  State<StatefulWidget> createState() => ImportStakerState();
}

class ImportStakerState extends State<ImportStaker> {
  StakerData? parsed;

  @override
  Widget build(BuildContext context) {
    final onPressed = parsed != null ? () => widget.onImported(parsed!) : null;
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 250,
              child: TextFormField(
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  onChanged: (str) {
                    setState(() {
                      parsed = null;
                      try {
                        parsed = StakerData.deserialize(str);
                      } catch (_) {}
                    });
                  }),
            ),
            TextButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.copy_all),
                label: const Text("Import"))
          ],
        ),
        if (parsed == null)
          const Text("Invalid staker data",
              style: TextStyle(color: Colors.red)),
      ],
    );
  }
}

class RunMinting extends ConsumerWidget {
  final BlockchainClient client;

  const RunMinting({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final production = ref.watch(podBlockProductionProvider);
    if (production is ActivePodBlockProductionState) {
      final stop = production.stop;
      if (stop == null) {
        return inactive(context, ref);
      } else {
        // TODO: code smell: not using local "stop" variable
        return active(context, ref,
            () => ref.read(podBlockProductionProvider.notifier).stop());
      }
    } else {
      return inactive(context, ref);
    }
  }

  Widget active(BuildContext context, WidgetRef ref, Function() stop) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Staking is active.",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
              .pad8,
          SizedBox(
            width: 400,
            child: const Text(
              "Your device is making blocks in the background. Network and power consumption may be higher than normal.",
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ).pad8,
          ),
          SizedBox(
            width: 400,
            child: const Text(
              "If you recently registered, the network will place you into a delay period before you can make new blocks. This is to prevent abuse. Block production will automatically begin when it can.",
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ).pad8,
          ),
          const Divider(),
          editStakeSlider(ref),
          TextButton.icon(
            onPressed: stop,
            label: const Text("Stop"),
            icon: const Icon(Icons.stop),
          ).pad8,
        ],
      );

  Widget inactive(BuildContext context, WidgetRef ref) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Staking is inactive.",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
              .pad8,
          const Text(
            "Your device is not currently making blocks, but you can start at any time.",
            style: TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ).pad8,
          const Divider(),
          editStakeSlider(ref),
          TextButton.icon(
                  onPressed: () =>
                      ref.read(podBlockProductionProvider.notifier).start(),
                  label: const Text("Start"),
                  icon: const Icon(Icons.play_arrow))
              .pad8,
          TextButton.icon(
            onPressed: () => ref.read(podStakingProvider.notifier).reset(),
            label: const Text("Delete Staker"),
            icon: const Icon(Icons.delete),
          ).pad8,
        ],
      );

  Widget editStakeSlider(WidgetRef ref) => FutureBuilder(
      future: ref.watch(podWalletProvider.future),
      builder: (context, snapshot) => snapshot.hasData
          ? EditStakeSlider(wallet: snapshot.data!)
          : const CircularProgressIndicator());

  static final log = Logger("MintingWidget");
}

class EditStakeSlider extends ConsumerStatefulWidget {
  final Wallet wallet;
  const EditStakeSlider({
    super.key,
    required this.wallet,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => EditStakeSliderState();
}

class EditStakeSliderState extends ConsumerState<EditStakeSlider> {
  late double desiredStake;
  late Int64 initialStake;
  Transaction? updateTransaction;

  @override
  void initState() {
    super.initState();
    initialStake = widget.wallet.stakedFunds;
    desiredStake = initialStake.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    if (updateTransaction != null) {
      return const Center(child: CircularProgressIndicator());
    }
    final liquid = widget.wallet.liquidFunds;
    return Column(
      children: [
        Text("Staked Funds: $initialStake"),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Slider(
              value: desiredStake.toDouble(),
              min: minimumRegistrationQuantity.toDouble(), // TODO
              max: (liquid + initialStake).toDouble(),
              divisions: 69,
              onChanged: (value) {
                setState(() {
                  desiredStake = value;
                });
              },
              label: desiredStake.toString(),
            ),
            saveButton,
          ],
        ),
      ],
    );
  }

  Widget get saveButton {
    Function()? onPressed;
    if (Int64(desiredStake.round()) != initialStake) {
      onPressed = () async {
        final inputs = widget.wallet.spendableOutputs.entries
            .where((e) => e.value.hasAccount())
            .map((e) => TransactionInput(reference: e.key))
            .toList();
        final accountEntry = widget.wallet.spendableOutputs.entries
            .firstWhere((e) => e.value.hasAccountRegistration());
        final client = ref.read(podBlockchainClientProvider)!;

        final transaction = await widget.wallet.payAndAttest(
          client,
          Transaction(
            inputs: inputs,
            outputs: [
              TransactionOutput(
                quantity:
                    Int64(desiredStake.round()) - accountEntry.value.quantity,
                lockAddress: widget.wallet.defaultLockAddress,
                account: accountEntry.key,
              ),
            ],
          ),
        );
        setState(() {
          updateTransaction = transaction;
        });
        await client.broadcastTransaction(transaction);
        await client.confirmTransaction(transaction.id);
        setState(() {
          updateTransaction = null;
        });
      };
    }
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.save),
      label: const Text("Save"),
    );
  }
}

Future<bool> stakingIsInitialized(FlutterSecureStorage storage) async =>
    await storage.containsKey(key: "blockchain-staker-vrf-sk") &&
    await storage.containsKey(key: "blockchain-staker-account") &&
    await storage.containsKey(key: "blockchain-staker-operator-sk");
