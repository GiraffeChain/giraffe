import 'package:blockchain_app/providers/social.dart';
import 'package:blockchain_app/providers/wallet.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StreamedSocialView extends ConsumerWidget {
  final BlockchainClient client;

  const StreamedSocialView({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(podWalletProvider)) {
      AsyncData(:final value) => SocialView(
          wallet: value,
          client: client,
        ),
      AsyncError(:final error) =>
        Center(child: Text("An error occurred: $error")),
      _ => const Center(child: CircularProgressIndicator())
    };
  }
}

class SocialView extends ConsumerWidget {
  const SocialView({
    super.key,
    required this.wallet,
    required this.client,
  });

  final Wallet wallet;
  final BlockchainClient client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(podSocialProvider);
    return switch (state) {
      AsyncData(:final value) => _loaded(ref, value),
      AsyncError(:final error) =>
        Center(child: Text("An error occurred: $error")),
      _ => const Center(child: CircularProgressIndicator())
    };
  }

  Widget _loaded(WidgetRef ref, SocialState state) {
    Widget body;
    if (state is AntiSocial) {
      body = _antiSocial(ref, state);
    } else if (state is Social) {
      body = _social(ref, state);
    } else {
      throw Exception("Unknown state: $state");
    }
    return Card(
      child: Center(child: body),
    );
  }

  Widget _antiSocial(WidgetRef ref, AntiSocial state) {
    return TextButton.icon(
        label: const Text("Create User"),
        icon: const Icon(Icons.person_add),
        onPressed: () => ref
            .read(podSocialProvider.notifier)
            .createUser(firstName: "Alice"));
  }

  Widget _social(WidgetRef ref, SocialState state) {
    return TextButton.icon(
        label: const Text("Add Friend"),
        icon: const Icon(Icons.person_add),
        onPressed: () {});
  }
}
