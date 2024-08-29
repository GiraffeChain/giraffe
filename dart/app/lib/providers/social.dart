import 'package:blockchain_app/providers/blockchain_client.dart';
import 'package:blockchain_app/providers/graph_client.dart';
import 'package:blockchain_app/providers/wallet.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'social.freezed.dart';
part 'social.g.dart';

@riverpod
class PodSocial extends _$PodSocial {
  @override
  Future<SocialState> build() async {
    final wallet = await ref.watch(podWalletProvider.future);
    ({TransactionOutputReference userRef, Vertex userVertex})? user;
    ({TransactionOutputReference profileRef, Vertex profileVertex})? profile;
    for (final entry in wallet.spendableOutputs.entries) {
      if (entry.value.value.hasGraphEntry()) {
        final graphEntry = entry.value.value.graphEntry;
        if (graphEntry.hasVertex()) {
          final vertex = graphEntry.vertex;
          if (vertex.label == "user") {
            user = (userRef: entry.key, userVertex: vertex);
          } else if (vertex.label == "profile") {
            profile = (profileRef: entry.key, profileVertex: vertex);
          }
        }
      }
    }
    if (user == null || profile == null) {
      return const AntiSocial();
    }
    final client = ref.read(podBlockchainClientProvider);
    final outgoingFriends =
        await client.queryEdges("friend", user.userRef, null, []);
    final incomingFriends =
        await client.queryEdges("friend", null, user.userRef, []);
    final friends = [...outgoingFriends.where(incomingFriends.contains)];
    outgoingFriends.removeWhere(friends.contains);
    incomingFriends.removeWhere(friends.contains);

    final profileData = ProfileData(
      firstName: profile.profileVertex.data.fields["firstName"]?.stringValue,
      lastName: profile.profileVertex.data.fields["lastName"]?.stringValue,
    );

    return Social(
      user: user.userRef,
      profile: profile.profileRef,
      profileData: profileData,
      outgoingFriendRequests: outgoingFriends,
      incomingFriendRequests: incomingFriends,
      friends: friends,
    );
  }

  createUser(ProfileData data) async {
    state = const AsyncLoading();
    try {
      final graph = await ref.watch(podGraphClientProvider.future);
      final userOutput = graph.createVertexOutput(label: "user");
      final profileOutput = graph.createVertexOutput(label: "profile", data: {
        "firstName": data.firstName,
        "lastName": data.lastName,
      });
      final edgeOutput = graph.createEdgeOutput(
          label: "userProfile",
          a: TransactionOutputReference(index: 1),
          b: TransactionOutputReference(index: 0));
      final wallet = await ref.watch(podWalletProvider.future);
      final client = ref.read(podBlockchainClientProvider);
      final tx = await wallet.payAndAttest(client,
          Transaction(outputs: [userOutput, profileOutput, edgeOutput]));
      await client.broadcastTransaction(tx);
      final userRef =
          TransactionOutputReference(transactionId: tx.id, index: 0);
      final profileRef =
          TransactionOutputReference(transactionId: tx.id, index: 1);
      state = AsyncData(Social(
          user: userRef,
          profile: profileRef,
          profileData: data,
          outgoingFriendRequests: [],
          incomingFriendRequests: [],
          friends: []));
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<List<(TransactionOutputReference, ProfileData)>> findUsers(
      {String? firstName, String? lastName}) async {
    final client = ref.read(podBlockchainClientProvider);
    final whereClauses = <WhereClause>[];
    if (firstName != null) {
      whereClauses.add(WhereClause("firstName", "==", firstName));
    }
    if (lastName != null) {
      whereClauses.add(WhereClause("lastName", "==", lastName));
    }
    final profileIds = await client.queryVertices("profile", whereClauses);
    final profileVertices = await Future.wait(profileIds.map((id) async =>
        (await client.getTransactionOutputOrRaise(id))
            .value
            .graphEntry
            .vertex));
    final profiles = profileVertices
        .map((vertex) => ProfileData(
              firstName: vertex.data.fields["firstName"]?.stringValue,
              lastName: vertex.data.fields["lastName"]?.stringValue,
            ))
        .toList();
    final userIds = await Future.wait(profileIds.map((id) async =>
        (await client.queryEdges("userProfile", id, null, [])).first));
    return [
      for (int i = 0; i < profiles.length; i++) (userIds[i], profiles[i])
    ];
  }

  addFriend(TransactionOutputReference friendId) async {
    try {
      final s = await future;
      if (s is! Social) {
        throw Exception("User must be created before adding friends");
      }
      if (s.friends.contains(friendId)) {
        throw Exception("User is already a friend");
      }
      if (s.outgoingFriendRequests.contains(friendId)) {
        throw Exception("Friend request already sent");
      }
      final graph = await ref.read(podGraphClientProvider.future);
      await graph.createEdge(label: "friend", a: s.user, b: friendId);
      if (s.incomingFriendRequests.contains(friendId)) {
        state = AsyncData(s.copyWith(
            incomingFriendRequests:
                s.incomingFriendRequests.where((f) => f != friendId).toList(),
            friends: [...s.friends, friendId]));
      } else {
        state = AsyncData(s.copyWith(
            outgoingFriendRequests: [...s.outgoingFriendRequests, friendId]));
      }
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }
}

abstract class SocialState {
  const SocialState();
}

class AntiSocial extends SocialState {
  const AntiSocial() : super();
}

@freezed
class Social extends SocialState with _$Social {
  const factory Social({
    required TransactionOutputReference user,
    required TransactionOutputReference profile,
    required ProfileData profileData,
    required List<TransactionOutputReference> outgoingFriendRequests,
    required List<TransactionOutputReference> incomingFriendRequests,
    required List<TransactionOutputReference> friends,
  }) = _Social;
}

@freezed
class ProfileData with _$ProfileData {
  const factory ProfileData({
    String? firstName,
    String? lastName,
  }) = _ProfileData;
}
