import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings.g.dart';
part 'settings.freezed.dart';

@Riverpod(keepAlive: true)
class PodSettings extends _$PodSettings {
  @override
  SettingsState build() => const SettingsState(
        host: "localhost",
        port: 2024,
        secure: false,
      );

  void setRpc(String host, int port, bool secure) {
    state = state.copyWith(host: host, port: port, secure: secure);
  }
}

@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    required String host,
    required int port,
    required bool secure,
  }) = _SettingsState;
}
