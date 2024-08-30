import 'package:blockchain_app/providers/blockchain_client.dart';
import 'package:blockchain_app/providers/canonical_head.dart';
import 'package:blockchain_app/providers/graph_client.dart';
import 'package:blockchain_app/providers/wallet.dart';
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
    ref.watch(podCanonicalHeadProvider);
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

    final profileData = ProfileData(
      firstName: profile.profileVertex.data.fields["firstName"]?.stringValue,
      lastName: profile.profileVertex.data.fields["lastName"]?.stringValue,
    );

    final client = ref.read(podBlockchainClientProvider);
    final outgoingFriendEdges =
        await client.queryEdges("friend", user.userRef, null, []);
    final outgoingFriends =
        await Future.wait(outgoingFriendEdges.map(client.outVertex));
    final incomingFriendEdges =
        await client.queryEdges("friend", null, user.userRef, []);
    final incomingFriends =
        await Future.wait(incomingFriendEdges.map(client.inVertex));
    final friends = [...outgoingFriends.where(incomingFriends.contains)];
    outgoingFriends.removeWhere(friends.contains);
    incomingFriends.removeWhere(friends.contains);
    final friendData = FriendData(
      outgoingFriendRequests: outgoingFriends,
      incomingFriendRequests: incomingFriends,
      friends: friends,
    );

    return Social(
      user: user.userRef,
      profile: profile.profileRef,
      profileData: profileData,
      friendData: friendData,
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
          friendData: const FriendData(
              outgoingFriendRequests: [],
              incomingFriendRequests: [],
              friends: [])));
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
    final results = <(TransactionOutputReference, ProfileData)>[];
    for (final profileId in profileIds) {
      final profileOutput = await client.getTransactionOutputOrRaise(profileId);
      final profile = ProfileData.fromTransactionOutput(profileOutput);
      final userProfileEdgeId =
          (await client.queryEdges("userProfile", profileId, null, [])).first;
      final userId = await client.outVertex(userProfileEdgeId);

      results.add((userId, profile));
    }
    return results;
  }

  addFriend(TransactionOutputReference friendId) async {
    try {
      final s = await future;
      if (s is! Social) {
        throw Exception("User must be created before adding friends");
      }
      final friendData = s.friendData;
      if (friendData.friends.contains(friendId)) {
        throw Exception("User is already a friend");
      }
      if (friendData.outgoingFriendRequests.contains(friendId)) {
        throw Exception("Friend request already sent");
      }
      final graph = await ref.read(podGraphClientProvider.future);
      await graph.createEdge(label: "friend", a: s.user, b: friendId);
      final FriendData updatedFriendData;
      if (friendData.incomingFriendRequests.contains(friendId)) {
        updatedFriendData = friendData.copyWith(
          incomingFriendRequests: friendData.incomingFriendRequests
              .where((f) => f != friendId)
              .toList(),
          friends: [...friendData.friends, friendId],
        );
      } else {
        updatedFriendData = friendData.copyWith(
          outgoingFriendRequests: [
            ...friendData.outgoingFriendRequests,
            friendId
          ],
        );
      }
      state = AsyncData(s.copyWith(friendData: updatedFriendData));
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<ProfileData> fetchProfileByUserId(
      TransactionOutputReference userId) async {
    final client = ref.read(podBlockchainClientProvider);
    final profileEdge =
        (await client.queryEdges("userProfile", null, userId, [])).first;
    final profileId = await client.inVertex(profileEdge);
    final profile = await client.getTransactionOutputOrRaise(profileId);
    return ProfileData.fromTransactionOutput(profile);
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
    required FriendData friendData,
  }) = _Social;
}

@freezed
class ProfileData with _$ProfileData {
  const factory ProfileData({
    String? firstName,
    String? lastName,
  }) = _ProfileData;

  factory ProfileData.fromTransactionOutput(TransactionOutput output) =>
      ProfileData(
        firstName: output
            .value.graphEntry.vertex.data.fields["firstName"]?.stringValue,
        lastName:
            output.value.graphEntry.vertex.data.fields["lastName"]?.stringValue,
      );
}

@freezed
class FriendData with _$FriendData {
  const factory FriendData({
    required List<TransactionOutputReference> outgoingFriendRequests,
    required List<TransactionOutputReference> incomingFriendRequests,
    required List<TransactionOutputReference> friends,
  }) = _FriendData;
}
