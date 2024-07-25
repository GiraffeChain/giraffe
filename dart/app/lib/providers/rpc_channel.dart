import 'package:blockchain_app/providers/settings.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:grpc/grpc.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rpc_channel.g.dart';

@riverpod
class PodRpcChannel extends _$PodRpcChannel {
  @override
  ClientChannel build() {
    final settings = ref.watch(podSettingsProvider);
    final channel = RpcClient.makeChannel(
      host: settings.host,
      port: settings.port,
      secure: settings.secure,
    );

    ref.onDispose(channel.shutdown);
    return channel;
  }
}
