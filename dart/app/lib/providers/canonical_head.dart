import 'package:blockchain_sdk/sdk.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'blockchain_client.dart';

part 'canonical_head.g.dart';

@Riverpod(keepAlive: true)
class PodCanonicalHead extends _$PodCanonicalHead {
  @override
  Stream<BlockId> build() async* {
    final client = ref.read(podBlockchainClientProvider);
    yield await client.canonicalHeadId;
    yield* client.adoptions;
  }
}
