import 'package:giraffe_sdk/sdk.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/streams.dart';

import 'blockchain_client.dart';

part 'canonical_head.g.dart';

@Riverpod(keepAlive: true)
class PodCanonicalHead extends _$PodCanonicalHead {
  @override
  Stream<BlockId> build() async* {
    final client = ref.read(podBlockchainClientProvider)!;
    yield await client.canonicalHeadId;
    yield* RetryStream(() => client.adoptions);
  }
}
