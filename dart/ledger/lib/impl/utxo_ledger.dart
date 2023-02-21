import 'package:bit_array/bit_array.dart';
import 'package:blockchain_codecs/codecs.dart';
import 'package:blockchain_common/store.dart';
import 'package:blockchain_ledger/impl/ops.dart';
import 'package:blockchain_ledger/impl/transaction_syntax_validation.dart';
import 'package:blockchain_ledger/ledger.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'dart:convert' show utf8;
import 'package:crypto/crypto.dart';

class UtxoLedger extends Ledger {
  final Future<TransactionOutput> Function(TransactionOutputReference)
      _fetchTransactionOutput;

  Store<TransactionId, BitArray> _txos;

  UtxoLedger(this._fetchTransactionOutput, this._txos);

  @override
  Future<void> apply(Transaction transaction) async {
    for (final input in transaction.inputs) {
      final reference = input.reference;
      final previous = await _txos.getOrRaise(reference.transactionId);
      previous[reference.index] = false;
    }

    final newUtxos = BitArray(transaction.outputs.length);

    for (var i = 0; i < transaction.outputs.length; i++) {
      newUtxos[i] = true;
    }
    _txos.set(transaction.id, newUtxos);
  }

  @override
  Future<void> remove(Transaction transaction) async {
    await _txos.delete(transaction.id);
    for (final input in transaction.inputs) {
      final reference = input.reference;
      final previous = await _txos.getOrRaise(reference.transactionId);
      previous[reference.index] = true;
      await _txos.set(reference.transactionId, previous);
    }
  }

  @override
  Future<List<String>> validate(Transaction transaction) async {
    final syntaxValidationErrors = validateTransactionSyntax(transaction);
    if (syntaxValidationErrors.isNotEmpty) {
      return syntaxValidationErrors;
    }

    final spentOutputReferences =
        transaction.inputs.map((i) => i.reference).toList();

    for (final reference in spentOutputReferences) {
      if (!(await txoIsSpendable(reference))) {
        return [
          "Transaction Output id=${reference.transactionId.show} index=${reference.index} is not spendable"
        ];
      }
    }

    final spentOutputs = await Stream.fromIterable(transaction.inputs)
        .map((i) => i.reference)
        .asyncMap(_fetchTransactionOutput)
        .toList();

    for (int i = 0; i < transaction.inputs.length; i++) {
      final input = transaction.inputs[i];
      final reference = input.reference;
      final output = transaction.outputs[i];
      final expectedHash = sha256.convert(utf8.encode(input.challenge.script));
      if (!(output.account.id == expectedHash.bytes)) {
        return [
          "Challenge for id=${reference.transactionId.show} index=${reference.index} was incorrect"
        ];
      }
      if (!(await executeScript(
          input.challenge.script, input.challengeArguments))) {
        return [
          "Challenge args for id=${reference.transactionId.show} index=${reference.index} was incorrect"
        ];
      }
    }

    final inputsSum = spentOutputs
        .where((o) => o.value.hasCoin())
        .map((o) => o.value.coin.quantityNum)
        .fold<BigInt>(BigInt.zero, ((a, b) => a + b));

    final outputsSum = transaction.outputs
        .where((o) => o.value.hasCoin())
        .map((o) => o.value.coin.quantityNum)
        .fold<BigInt>(BigInt.zero, ((a, b) => a + b));

    if (outputsSum > inputsSum) {
      return ["Transaction outputSum=$outputsSum exceeded inputSum=$inputsSum"];
    }

    return [];
  }

  Future<bool> txoIsSpendable(TransactionOutputReference reference) async {
    final indices = await _txos.get(reference.transactionId);
    if (indices == null)
      return false;
    else {
      return indices[reference.index];
    }
  }

  Future<bool> executeScript(String script, List<List<int>> arguments) async {
    // TODO
    return true;
  }
}
