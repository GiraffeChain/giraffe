import 'package:blockchain_app/providers/social.dart';
import 'package:blockchain_app/providers/wallet.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
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
      AsyncError(:final error, :final stackTrace) =>
        Center(child: Text("An error occurred: $error\n$stackTrace")),
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
    return ProfileEditor(
        onSave: (data) =>
            ref.read(podSocialProvider.notifier).createUser(data));
  }

  Widget _social(WidgetRef ref, Social state) {
    return ActiveSocialView(state: state);
  }
}

class ProfileEditor extends StatefulWidget {
  final Function(ProfileData) onSave;

  const ProfileEditor({super.key, required this.onSave});

  @override
  State<StatefulWidget> createState() => ProfileEditorState();
}

class ProfileEditorState extends State<ProfileEditor> {
  String firstName = "";
  String lastName = "";

  // TODO: Use Forms
  @override
  Widget build(BuildContext context) => Column(
        children: [
          TextField(
            decoration: const InputDecoration(labelText: "First Name"),
            onChanged: (value) => setState(() => firstName = value),
          ),
          TextField(
            decoration: const InputDecoration(labelText: "Last Name"),
            onChanged: (value) => setState(() => lastName = value),
          ),
          ElevatedButton(
            onPressed: () => widget.onSave(ProfileData(
                firstName: firstName.isEmpty ? null : firstName,
                lastName: lastName.isEmpty ? null : lastName)),
            child: const Text("Save"),
          ),
        ],
      );
}

class ActiveSocialView extends ConsumerWidget {
  final Social state;

  const ActiveSocialView({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
            "Hello, ${state.profileData.firstName ?? "Stranger"} ${state.profileData.lastName ?? ""}!",
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        Text("You have ${state.friends.length} friends.",
            style: const TextStyle(fontSize: 16)),
        Text(
            "You have ${state.outgoingFriendRequests.length} outgoing friend requests.",
            style: const TextStyle(fontSize: 16)),
        Text(
            "You have ${state.incomingFriendRequests.length} incoming friend requests.",
            style: const TextStyle(fontSize: 16)),
        const Divider(),
        const UserSearch(),
      ],
    );
  }
}

class UserSearch extends ConsumerStatefulWidget {
  const UserSearch({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => UserSearchState();
}

class UserSearchState extends ConsumerState<UserSearch> {
  List<(TransactionOutputReference userRef, ProfileData profile)> results = [];
  String firstName = "";
  String lastName = "";
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 600,
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 200,
                  height: 80,
                  child: TextField(
                    decoration: const InputDecoration(labelText: "First Name"),
                    onChanged: (value) => firstName = value,
                  ),
                ),
                SizedBox(
                  width: 200,
                  height: 80,
                  child: TextField(
                    decoration: const InputDecoration(labelText: "Last Name"),
                    onChanged: (value) => lastName = value,
                  ),
                ),
                IconButton(
                    onPressed: () async {
                      final social = ref.read(podSocialProvider.notifier);
                      final users = await social.findUsers(
                          firstName: firstName.isEmpty ? null : firstName,
                          lastName: lastName.isEmpty ? null : lastName);
                      setState(() => results = users);
                    },
                    icon: const Icon(Icons.search))
              ],
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final (userRef, profile) in results)
                    ListTile(
                      title: Text("${profile.firstName} ${profile.lastName}"),
                      onTap: () => ref
                          .read(podSocialProvider.notifier)
                          .addFriend(userRef),
                    )
                ],
              ),
            ),
          ],
        ),
      );
}
