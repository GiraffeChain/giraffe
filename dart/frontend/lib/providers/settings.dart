import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:giraffe_frontend/providers/storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings.g.dart';
part 'settings.freezed.dart';

@Riverpod(keepAlive: true)
class PodSettings extends _$PodSettings {
  @override
  Future<SettingsState> build() async {
    final previous =
        await ref.read(podSecureStorageProvider.notifier).apiAddress;
    return SettingsState(apiAddress: previous);
  }

  void setApiAddress(String? address) {
    if (address != null) {
      ref.read(podSecureStorageProvider.notifier).setApiAddress(address);
    }
    state = AsyncData(SettingsState(apiAddress: address));
  }
}

@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    required String? apiAddress,
  }) = _SettingsState;
}
