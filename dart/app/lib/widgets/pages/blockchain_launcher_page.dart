import 'package:blockchain/private_testnet.dart';
import 'package:blockchain_app/providers/settings.dart';
import 'package:blockchain_app/providers/wallet_key.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bip39/bip39.dart' as bip39;

class LauncherPage extends ConsumerStatefulWidget {
  const LauncherPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => LauncherPageState();
}

class LauncherPageState extends ConsumerState<LauncherPage> {
  LaunchSettings? launchSettings;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: SizedBox.fromSize(
            size: const Size(500, 500),
            child: Card(
              child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: launchSettings == null
                      ? configForm(context)
                      : walletForm(context)),
            ),
          ),
        ),
      );

  Widget configForm(BuildContext context) => BlockchainConfigForm(
        onSubmit: (context, config) => setState(() => launchSettings = config),
      );
  Widget walletForm(BuildContext context) =>
      WalletSelectionForm(onSelected: (key) {
        ref.read(podWalletKeyProvider.notifier).setKey(key);
        ref.read(podSettingsProvider.notifier).setRpc(launchSettings!.rpcHost,
            launchSettings!.rpcPort, launchSettings!.rpcSecure);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Navigator(
                      initialRoute: '/',
                      onGenerateRoute: FluroRouter.appRouter.generator,
                    )));
      });
}

class BlockchainConfigForm extends StatefulWidget {
  const BlockchainConfigForm({super.key, required this.onSubmit});
  final void Function(BuildContext, LaunchSettings) onSubmit;

  @override
  State<StatefulWidget> createState() => BlockchainConfigFormState();
}

class BlockchainConfigFormState extends State<BlockchainConfigForm> {
  String? rpcHost;
  String? rpcPort;
  @override
  Widget build(BuildContext context) => Column(
        children: [
          TextField(
            onChanged: (v) => rpcHost = v,
            decoration:
                const InputDecoration(hintText: "RPC Host. i.e. localhost"),
          ),
          TextField(
            onChanged: (v) => rpcPort = v,
            decoration: const InputDecoration(hintText: "RPC Port. i.e. 2024"),
          ),
          IconButton(
              onPressed: () => _submit(context), icon: const Icon(Icons.send))
        ],
      );

  _submit(BuildContext context) {
    final config = LaunchSettings(
      rpcHost: rpcHost ?? "localhost",
      rpcPort: _parsedPort ?? 2024,
      rpcSecure: false, // TODO
    );
    widget.onSubmit(context, config);
  }

  int? get _parsedPort => (rpcPort != null) ? int.tryParse(rpcPort!) : null;
}

class LaunchSettings {
  final String rpcHost;
  final int rpcPort;
  final bool rpcSecure;

  LaunchSettings(
      {required this.rpcHost, required this.rpcPort, required this.rpcSecure});
}

class WalletSelectionForm extends StatefulWidget {
  const WalletSelectionForm({
    super.key,
    required this.onSelected,
  });

  final Function(Ed25519KeyPair) onSelected;

  @override
  State<StatefulWidget> createState() => WalletSelectionFormState();
}

class WalletSelectionFormState extends State<WalletSelectionForm> {
  @override
  Widget build(BuildContext context) => Column(
        children: [
          const Text("Select a wallet"),
          TextButton.icon(
            label: const Text("Public"),
            onPressed: () async =>
                widget.onSelected(await PrivateTestnet.DefaultKeyPair),
            icon: const Icon(Icons.people),
          ),
          TextButton.icon(
            label: const Text("Load"),
            onPressed: () {},
            icon: const Icon(Icons.save),
          ),
          TextButton.icon(
            label: const Text("Create"),
            onPressed: () => _create(context),
            icon: const Icon(Icons.add),
          ),
          TextButton.icon(
            label: const Text("Import"),
            onPressed: () {},
            icon: const Icon(Icons.text_format),
          ),
        ],
      );

  void _create(BuildContext context) async {
    final Ed25519KeyPair? result = await showDialog(
        context: context, builder: (context) => CreateWalletModal());
    if (result != null) widget.onSelected(result);
  }
}

class CreateWalletModal extends StatefulWidget {
  const CreateWalletModal({super.key});

  @override
  State<StatefulWidget> createState() => CreateWalletModalState();
}

class CreateWalletModalState extends State<CreateWalletModal> {
  String? passphrase;
  bool loading = false;
  (String, Ed25519KeyPair)? result;
  @override
  Widget build(BuildContext context) => SimpleDialog(
        title: const Text("Create Wallet"),
        children: result != null
            ? done(context)
            : loading
                ? const [Center(child: CircularProgressIndicator())]
                : requestPassprase(context),
      );

  _generate(BuildContext context) async {
    setState(() => loading = true);
    final mnemonic = bip39.generateMnemonic();
    final seed64 = bip39.mnemonicToSeed(mnemonic, passphrase: passphrase ?? "");
    final seed = seed64.hash256;
    final keyPair = await ed25519.generateKeyPairFromSeed(seed);
    setState(() {
      result = (mnemonic, keyPair);
    });
    // TODO: Save KeyPair
    return mnemonic;
  }

  List<Widget> requestPassprase(BuildContext context) => [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            onChanged: (v) => passphrase = v,
            decoration: const InputDecoration(hintText: "Passphrase"),
          ),
        ),
        TextButton(
          child: const Text("Create"),
          onPressed: () => _generate(context),
        )
      ];

  List<Widget> done(BuildContext context) => [
        const Text("Your mnemonic is:", style: TextStyle(fontSize: 18)),
        Text(result!.$1),
        const Text(
            "Please record these words in a safe place. Once this dialog is closed, they can't be recovered.",
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
        TextButton(
          child: const Text("Close"),
          onPressed: () => Navigator.pop(context, result!.$2),
        ),
      ]
          .map(
            (w) => Padding(padding: const EdgeInsets.all(8.0), child: w),
          )
          .toList();
}
