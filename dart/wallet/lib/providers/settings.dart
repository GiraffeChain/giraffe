import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings.g.dart';
part 'settings.freezed.dart';

@Riverpod(keepAlive: true)
class PodSettings extends _$PodSettings {
  @override
  SettingsState build() => const SettingsState(
        apiAddress: null, // "http://localhost:2024/api",
      );

  void setApiAddress(String? address) {
    state = state.copyWith(apiAddress: address);
  }
}

@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    required String? apiAddress,
  }) = _SettingsState;
}
