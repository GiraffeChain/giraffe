import 'package:blockchain_app/providers/blockchain_client.dart';
import 'package:blockchain_app/providers/graph_client.dart';
import 'package:blockchain_app/providers/wallet.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
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

    return Social(
      user: user.userRef,
      profile: profile.profileRef,
      firstName: profile.profileVertex.data.fields["firstName"]?.stringValue,
      lastName: profile.profileVertex.data.fields["lastName"]?.stringValue,
      outgoingFriendRequests: outgoingFriends,
      incomingFriendRequests: incomingFriends,
      friends: friends,
    );
  }

  createUser({String? firstName, String? lastName}) async {
    state = const AsyncLoading();
    try {
      final graph = await ref.watch(podGraphClientProvider.future);
      final userRef = await graph.createVertex(label: "user");
      final profileRef = await graph.createVertex(label: "profile", data: {
        "firstName": firstName,
        "lastName": lastName,
      });
      await graph.createEdge(
        label: "userProfile",
        a: profileRef,
        b: userRef,
      );
      state = AsyncData(Social(
          user: userRef,
          profile: profileRef,
          firstName: firstName,
          lastName: lastName,
          outgoingFriendRequests: [],
          incomingFriendRequests: [],
          friends: []));
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
    required String? firstName,
    required String? lastName,
    required List<TransactionOutputReference> outgoingFriendRequests,
    required List<TransactionOutputReference> incomingFriendRequests,
    required List<TransactionOutputReference> friends,
  }) = _Social;
}
