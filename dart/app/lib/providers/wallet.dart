import 'package:blockchain_sdk/sdk.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallet.g.dart';

@riverpod
class PodWallet extends _$PodWallet {
  @override
  Stream<Wallet> build(BlockchainView view) =>
      Stream.fromFuture(Wallet.genesis).asyncExpand((w) => w.streamed(view));
}
