import '../../providers/social.dart';
import '../../utils.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../giraffe_background.dart';
import '../giraffe_card.dart';

class SocialView extends ConsumerWidget {
  const SocialView({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Social"),
      ),
      body: GiraffeBackground(
          child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 600,
          child: GiraffeCard(
            child: body(context, ref),
          ).pad16,
        ),
      )),
    );
  }

  Widget body(BuildContext context, WidgetRef ref) {
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
    return body;
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
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Create Profile",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
                .pad16,
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: TextField(
                decoration: const InputDecoration(labelText: "First Name"),
                onChanged: (value) => setState(() => firstName = value),
              ).pad16,
            ),
            ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: TextField(
                  decoration: const InputDecoration(labelText: "Last Name"),
                  onChanged: (value) => setState(() => lastName = value),
                ).pad16),
            ElevatedButton(
              onPressed: () => widget.onSave(ProfileData(
                  firstName: firstName.isEmpty ? null : firstName,
                  lastName: lastName.isEmpty ? null : lastName)),
              child: const Text("Create"),
            ).pad16,
          ],
        ),
      ).pad16;
}

class ActiveSocialView extends ConsumerWidget {
  final Social state;

  const ActiveSocialView({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final left = leftColumn(ref);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        welcomeMessage(),
        Row(
          children: [if (left != null) left, rightColumn()],
        )
      ],
    );
  }

  Text welcomeMessage() {
    return Text(
        "Hello, ${state.profileData.firstName ?? "Stranger"} ${state.profileData.lastName ?? ""}!",
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold));
  }

  Widget? leftColumn(WidgetRef ref) {
    final curFriends = currentFriends(ref);
    final outFriends = outgoingRequests(ref);
    final inFriends = incomingFriendRequests(ref);
    if (curFriends == null && outFriends == null && inFriends == null) {
      return null;
    }
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
    return ConstrainedBox(
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
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SizedBox(
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Search Users",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                  .pad8,
              Row(
                children: [
                  SizedBox(
                    width: 200,
                    height: 80,
                    child: TextField(
                      decoration:
                          const InputDecoration(labelText: "First Name"),
                      onChanged: (value) => firstName = value,
                    ),
                  ).pad8,
                  SizedBox(
                    width: 200,
                    height: 80,
                    child: TextField(
                      decoration: const InputDecoration(labelText: "Last Name"),
                      onChanged: (value) => lastName = value,
                    ),
                  ).pad8,
                  IconButton(
                          onPressed: () async {
                            final social = ref.read(podSocialProvider.notifier);
                            final users = await social.findUsers(
                                firstName: firstName.isEmpty ? null : firstName,
                                lastName: lastName.isEmpty ? null : lastName);
                            setState(() => results = users);
                          },
                          icon: const Icon(Icons.search))
                      .pad8
                ],
              ),
              Expanded(
                child: resultsList(),
              ),
            ],
          ),
        ),
      );

  ListView resultsList() {
    final r = <Widget>[];
    // TODO: Omit self from search results?
    for (final (userRef, profile) in results) {
      r.add(ListTile(
        title: Row(
          children: [
            IconButton(
                    onPressed: () =>
                        ref.read(podSocialProvider.notifier).addFriend(userRef),
                    icon: const Icon(Icons.add))
                .pad8,
            Text("${profile.firstName} ${profile.lastName}").pad8,
          ],
        ),
      ));
    }
    return ListView(
      children: [
        for (final (userRef, profile) in results)
          ListTile(
            title: Row(
              children: [
                IconButton(
                        onPressed: () => ref
                            .read(podSocialProvider.notifier)
                            .addFriend(userRef),
                        icon: const Icon(Icons.add))
                    .pad8,
                Text("${profile.firstName} ${profile.lastName}").pad8,
              ],
            ),
          )
      ],
    );
  }
}
