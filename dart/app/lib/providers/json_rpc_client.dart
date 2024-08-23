import 'package:blockchain_app/providers/settings.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'json_rpc_client.g.dart';

@riverpod
class PodJsonRpcClient extends _$PodJsonRpcClient {
  @override
  JsonRpcClient build() {
    final settings = ref.watch(podSettingsProvider);
    return JsonRpcClient(
      baseAddress:
          "${settings.secure ? 'https' : 'http'}://${settings.host}:${settings.port}/api",
    );
  }
}
