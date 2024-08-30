import 'package:flutter/services.dart';

import '../../blockchain/private_testnet.dart';
import '../../providers/settings.dart';
import '../../providers/storage.dart';
import '../../providers/wallet_key.dart';
import 'package:giraffe_sdk/sdk.dart';
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
            decoration: const InputDecoration(hintText: "RPC Port. i.e. 2025"),
          ),
          IconButton(
              onPressed: () => _submit(context), icon: const Icon(Icons.send))
        ],
      );

  _submit(BuildContext context) {
    final config = LaunchSettings(
      rpcHost: rpcHost ?? "localhost",
      rpcPort: _parsedPort ?? 2025,
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

class WalletSelectionForm extends ConsumerStatefulWidget {
  const WalletSelectionForm({
    super.key,
    required this.onSelected,
  });

  final Function(Ed25519KeyPair) onSelected;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      WalletSelectionFormState();
}

class WalletSelectionFormState extends ConsumerState<WalletSelectionForm> {
  @override
  Widget build(BuildContext context) => Column(
        children: [
          const Text("Select a wallet",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton.icon(
            label: const Text("Public"),
            onPressed: () async =>
                widget.onSelected(await PrivateTestnet.defaultKeyPair),
            icon: const Icon(Icons.people),
          ),
          TextButton.icon(
            label: const Text("Create"),
            onPressed: () => _create(context),
            icon: const Icon(Icons.add),
          ),
          TextButton.icon(
            label: const Text("Import"),
            onPressed: () => _import(context),
            icon: const Icon(Icons.text_format),
          ),
          loadOrResetButtons(context),
        ],
      );

  Widget loadOrResetButtons(BuildContext context) => FutureBuilder(
        future: ref.watch(podSecureStorageProvider.notifier).containsWalletSk,
        builder: (context, snapshot) => !snapshot.hasData
            ? const CircularProgressIndicator()
            : snapshot.data!
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    TextButton.icon(
                      label: const Text("Load"),
                      onPressed: () => _load(context),
                      icon: const Icon(Icons.save),
                    ),
                    const VerticalDivider(),
                    TextButton.icon(
                      label: const Text("Delete"),
                      onPressed: () async {
                        await ref
                            .read(podSecureStorageProvider.notifier)
                            .deleteWalletSk();
                        setState(() {});
                      },
                      icon: const Icon(Icons.delete),
                    ),
                  ])
                : Container(),
      );

  void _create(BuildContext context) async {
    final Ed25519KeyPair? result = await showDialog(
        context: context, builder: (context) => const CreateWalletModal());
    if (result != null) {
      await ref.read(podSecureStorageProvider.notifier).setWalletSk(result.sk);
      widget.onSelected(result);
    }
  }

  void _import(BuildContext context) async {
    final Ed25519KeyPair? result = await showDialog(
        context: context, builder: (context) => const ImportWalletModal());
    if (result != null) {
      await ref.read(podSecureStorageProvider.notifier).setWalletSk(result.sk);
      widget.onSelected(result);
    }
  }

  void _load(BuildContext context) async {
    final sk = (await ref.read(podSecureStorageProvider.notifier).getWalletSk)!;
    final vk = Uint8List.fromList(await ed25519.getVerificationKey(sk));
    final Ed25519KeyPair result = Ed25519KeyPair(sk, vk);
    widget.onSelected(result);
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
        TextButton.icon(
          icon: const Icon(Icons.copy),
          label: Text(result!.$1),
          onPressed: () => Clipboard.setData(ClipboardData(text: result!.$1)),
        ),
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

class ImportWalletModal extends StatefulWidget {
  const ImportWalletModal({super.key});

  @override
  State<StatefulWidget> createState() => ImportWalletModalState();
}

class ImportWalletModalState extends State<ImportWalletModal> {
  String mnemonic = "";
  String passphrase = "";
  bool loading = false;
  (String, Ed25519KeyPair)? result;
  String? error;
  @override
  Widget build(BuildContext context) => SimpleDialog(
        title: const Text("Import Wallet"),
        children: result != null
            ? done(context)
            : loading
                ? const [Center(child: CircularProgressIndicator())]
                : requestInfo(context),
      );

  _generate(BuildContext context) async {
    if (!bip39.validateMnemonic(mnemonic)) {
      setState(() => error = "Invalid mnemonic");
    } else {
      final seed64 = bip39.mnemonicToSeed(mnemonic, passphrase: passphrase);
      final seed = seed64.hash256;
      setState(() => loading = true);
      final keyPair = await ed25519.generateKeyPairFromSeed(seed);
      setState(() {
        result = (mnemonic, keyPair);
      });
    }
  }

  List<Widget> requestInfo(BuildContext context) {
    final arr = <Widget>[
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          onChanged: (v) => mnemonic = v,
          decoration: const InputDecoration(hintText: "Mnemonic"),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          onChanged: (v) => passphrase = v,
          decoration: const InputDecoration(hintText: "Passphrase"),
        ),
      ),
    ];
    if (error != null) {
      arr.add(Text(error!,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)));
    }

    arr.add(TextButton(
      child: const Text("Import"),
      onPressed: () => _generate(context),
    ));
    return arr;
  }

  List<Widget> done(BuildContext context) => [
        const Text("Your wallet was imported successfully.",
            style: TextStyle(fontSize: 18)),
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
