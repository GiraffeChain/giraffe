import 'package:giraffe_sdk/sdk.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../blockchain/private_testnet.dart';

part 'transact.freezed.dart';
part 'transact.g.dart';

@riverpod
class PodTransact extends _$PodTransact {
  @override
  TransactState build() =>
      const TransactState(selectedInputs: {}, newOutputEntries: []);

  void selectInput(TransactionOutputReference ref) {
    state = state.copyWith(selectedInputs: {...state.selectedInputs, ref});
  }

  void unselectInput(TransactionOutputReference ref) {
    state =
        state.copyWith(selectedInputs: {...state.selectedInputs}..remove(ref));
  }

  void addOutput() async {
    state = state.copyWith(newOutputEntries: [
      ...state.newOutputEntries,
      ("0", (await PrivateTestnet.defaultLockAddress).show)
    ]);
  }

  void updateOutput(int index, String quantity, String address) {
    state = state.copyWith(
        newOutputEntries: [...state.newOutputEntries]
          ..removeAt(index)
          ..insert(index, (quantity, address)));
  }

  void removeOutput(int index) {
    state = state.copyWith(
        newOutputEntries: [...state.newOutputEntries]..removeAt(index));
  }

  void reset() {
    state = const TransactState(selectedInputs: {}, newOutputEntries: []);
  }
}

@freezed
class TransactState with _$TransactState {
  const factory TransactState(
          {required Set<TransactionOutputReference> selectedInputs,
          required List<(String quantity, String address)> newOutputEntries}) =
      _TransactState;
}
