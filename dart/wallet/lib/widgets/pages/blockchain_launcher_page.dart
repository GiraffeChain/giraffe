import 'dart:async';

import 'package:flutter/services.dart';
import 'package:giraffe_wallet/providers/wallet.dart';
import 'package:giraffe_wallet/utils.dart';
import 'package:giraffe_wallet/widgets/giraffe_background.dart';
import 'package:giraffe_wallet/widgets/giraffe_card.dart';

import '../../blockchain/private_testnet.dart';
import '../../providers/settings.dart';
import '../../providers/storage.dart';
import '../../providers/wallet_key.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bip39/bip39.dart' as bip39;

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => SettingsPageState();
}

class SettingsPageState extends ConsumerState<SettingsPage> {
  late String? apiAddress;
  String? error;
  bool valid = false;

  late final TextEditingController addressController;

  @override
  void initState() {
    super.initState();
    apiAddress = ref.read(podSettingsProvider).apiAddress;
    addressController = TextEditingController(text: apiAddress);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
          body: GiraffeBackground(
              child: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 500,
            child: GiraffeCard(child: settingsForm(context)),
          ),
        ),
      )));

  Column settingsForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Image(image: AssetImage("assets/images/logo_with_border.png")),
        const Text("Welcome to Giraffe Chain",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        addressField(context),
        walletForm(context),
        connectButton(context),
      ].padAll8,
    );
  }

  Widget addressField(BuildContext context) {
    const prompt = Text("Enter the API Address of a trusted relay node");
    Timer? timer;
    void onChanged(String updated) async {
      apiAddress = updated;
      setState(() {
        valid = false;
        error = null;
      });
      timer?.cancel();
      timer = null;
      try {
        final parsed = Uri.parse(updated);
        assert(parsed.scheme == "http" || parsed.scheme == "https");
      } catch (_) {
        setState(() {
          error = "Invalid URL";
          valid = false;
        });
        return;
      }
      error = "Attempting to connect...";
      timer = Timer(const Duration(milliseconds: 500), () async {
        try {
          await BlockchainClientFromJsonRpc(baseAddress: updated)
              .canonicalHeadId
              .timeout(const Duration(seconds: 2));
        } catch (e) {
          setState(() {
            error = "Failed to connect";
            valid = false;
          });
          return;
        }
        setState(() {
          error = null;
          valid = true;
        });
      });
    }

    final textField = TextField(
      onChanged: onChanged,
      controller: addressController,
      decoration: InputDecoration(
          hintText: apiAddress ?? "http://localhost:2024/api", label: prompt),
    );
    final errorField = error == null
        ? null
        : Text(error!, style: const TextStyle(color: Colors.red));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [textField, if (errorField != null) errorField],
    );
  }

  Widget walletForm(BuildContext context) => const WalletSelectionForm();

  Widget connectButton(BuildContext context) {
    final isValid = valid && ref.watch(podWalletKeyProvider) != null;
    final Function()? onPressed = isValid
        ? () {
            ref.read(podSettingsProvider.notifier).setApiAddress(apiAddress);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Navigator(
                          initialRoute: '/',
                          onGenerateRoute: FluroRouter.appRouter.generator,
                        )));
          }
        : null;
    return ElevatedButton.icon(
      label: const Text("Connect"),
      onPressed: onPressed,
      icon: const Icon(Icons.network_ping),
    );
  }
}

class WalletSelectionForm extends ConsumerStatefulWidget {
  const WalletSelectionForm({
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      WalletSelectionFormState();
}

class WalletSelectionFormState extends ConsumerState<WalletSelectionForm> {
  @override
  Widget build(BuildContext context) {
    if (ref.watch(podWalletKeyProvider) == null) {
      return uninitialized(context);
    } else {
      return initialized(context);
    }
  }

  Widget uninitialized(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Select a wallet",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton.icon(
            label: const Text("Public"),
            onPressed: () async =>
                onSelected(await PrivateTestnet.defaultKeyPair),
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
        ].padAll8,
      );

  Widget initialized(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Wallet is loaded",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
              .pad8,
          FutureBuilder(
              future: ref.watch(podWalletProvider.future),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final addressStr = snapshot.data!.defaultLockAddress.show;
                  return TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: addressStr));
                      },
                      label: Text(addressStr,
                          style: const TextStyle(fontSize: 12)),
                      icon: const Icon(Icons.copy));
                } else {
                  return const CircularProgressIndicator();
                }
              }).pad8,
          TextButton.icon(
            label: const Text("Unload"),
            onPressed: () =>
                ref.read(podWalletKeyProvider.notifier).setKey(null),
            icon: const Icon(Icons.power_off),
          ).pad8,
        ],
      );

  onSelected(Ed25519KeyPair key) {
    ref.read(podWalletKeyProvider.notifier).setKey(key);
  }

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
      onSelected(result);
    }
  }

  void _import(BuildContext context) async {
    final Ed25519KeyPair? result = await showDialog(
        context: context, builder: (context) => const ImportWalletModal());
    if (result != null) {
      await ref.read(podSecureStorageProvider.notifier).setWalletSk(result.sk);
      onSelected(result);
    }
  }

  void _load(BuildContext context) async {
    final sk = (await ref.read(podSecureStorageProvider.notifier).getWalletSk)!;
    final vk = Uint8List.fromList(await ed25519.getVerificationKey(sk));
    final Ed25519KeyPair result = Ed25519KeyPair(sk, vk);
    onSelected(result);
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
