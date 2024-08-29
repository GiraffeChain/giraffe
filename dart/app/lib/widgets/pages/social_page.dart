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
        welcomeMessage(),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [leftColumn(ref), rightColumn()],
        )
      ],
    );
  }

  Text welcomeMessage() {
    return Text(
        "Hello, ${state.profileData.firstName ?? "Stranger"} ${state.profileData.lastName ?? ""}!",
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold));
  }

  ConstrainedBox leftColumn(WidgetRef ref) {
    final curFriends = currentFriends(ref);
    final outFriends = outgoingRequests(ref);
    final inFriends = incomingFriendRequests(ref);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 300),
      child: Column(
        children: [
          if (curFriends != null) curFriends,
          if (outFriends != null) outFriends,
          if (inFriends != null) inFriends,
        ],
      ),
    );
  }

  Widget? currentFriends(WidgetRef ref) {
    if (state.friendData.friends.isEmpty) {
      return null;
    }
    return userList(ref, "Friends", state.friendData.friends);
  }

  Widget? outgoingRequests(WidgetRef ref) {
    if (state.friendData.outgoingFriendRequests.isEmpty) {
      return null;
    }
    return userList(ref, "Outgoing Friend Requests",
        state.friendData.outgoingFriendRequests);
  }

  Widget? incomingFriendRequests(WidgetRef ref) {
    if (state.friendData.incomingFriendRequests.isEmpty) {
      return null;
    }
    return userList(ref, "Incoming Friend Requests",
        state.friendData.incomingFriendRequests);
  }

  Widget userList(
      WidgetRef ref, String title, List<TransactionOutputReference> users) {
    final social = ref.read(podSocialProvider.notifier);
    return Card(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300, minWidth: 300),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              for (final friend in users)
                FutureBuilder(
                    future: social.fetchProfileByUserId(friend),
                    builder: (context, snapshot) => snapshot.hasData
                        ? Text(
                            "${snapshot.data?.firstName ?? ""} ${snapshot.data?.lastName ?? ""}")
                        : snapshot.hasError
                            ? Text(
                                "Error: ${snapshot.error}\n${snapshot.stackTrace}")
                            : const CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  Expanded rightColumn() {
    return const Expanded(
      child: Column(children: [
        UserSearch(),
      ]),
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
        height: 450,
        child: Card(
          child: Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 200,
                      height: 80,
                      child: TextField(
                        decoration:
                            const InputDecoration(labelText: "First Name"),
                        onChanged: (value) => firstName = value,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 200,
                      height: 80,
                      child: TextField(
                        decoration:
                            const InputDecoration(labelText: "Last Name"),
                        onChanged: (value) => lastName = value,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                        onPressed: () async {
                          final social = ref.read(podSocialProvider.notifier);
                          final users = await social.findUsers(
                              firstName: firstName.isEmpty ? null : firstName,
                              lastName: lastName.isEmpty ? null : lastName);
                          setState(() => results = users);
                        },
                        icon: const Icon(Icons.search)),
                  )
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
        ),
      );
}
