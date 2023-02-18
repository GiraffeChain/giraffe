import 'package:blockchain_codecs/codecs.dart';
import 'package:blockchain_ledger/impl/ops.dart';
import 'package:blockchain_ledger/ledger.dart';
import 'package:blockchain_protobuf/models/transaction.pb.dart';
import 'dart:convert' show utf8;
import 'package:crypto/crypto.dart';

class UtxoLedger extends Ledger {
  final Future<TransactionOutput> Function(TransactionOutputReference)
      _fetchTransactionOutput;

  // Hold the UTxO Set in-memory
  Map<TransactionId, Set<int>> _utxos;

  UtxoLedger(this._fetchTransactionOutput, this._utxos);

  @override
  Future<void> apply(Transaction transaction) async {
    transaction.inputs
        .map((i) => i.spentTransactionOutput)
        .forEach((reference) {
      final previous = _utxos[reference.transactionId]!;
      previous.remove(reference.index);
      if (previous.isEmpty) {
        _utxos.remove(reference.transactionId);
      }
    });

    final newUtxos = Set<int>();

    for (var i = 0; i < transaction.outputs.length; i++) {
      // Exclude donations
      if (transaction.outputs[i].hasSpendChallengeHash()) {
        newUtxos.add(i);
      }
    }
    _utxos[transaction.id] = newUtxos;
  }

  @override
  Future<void> remove(Transaction transaction) async {
    _utxos.remove(transaction.id);

    transaction.inputs
        .map((i) => i.spentTransactionOutput)
        .forEach((reference) {
      final previous = _utxos[reference.transactionId] ?? Set<int>();
      previous.add(reference.index);
      _utxos[reference.transactionId] = previous;
    });
  }

  @override
  Future<List<String>> validate(Transaction transaction) async {
    final spentOutputReferences =
        transaction.inputs.map((i) => i.spentTransactionOutput).toList();

    if (spentOutputReferences.length != spentOutputReferences.toSet().length) {
      return ["Transaction attempts to double-spend"];
    }

    for (final reference in spentOutputReferences) {
      if (!txoIsSpendable(reference)) {
        return [
          "Transaction Output id=${reference.transactionId.show} index=${reference.index} is not spendable"
        ];
      }
    }

    final spentOutputs = await Stream.fromIterable(transaction.inputs)
        .map((i) => i.spentTransactionOutput)
        .asyncMap(_fetchTransactionOutput)
        .toList();

    for (int i = 0; i < transaction.inputs.length; i++) {
      final input = transaction.inputs[i];
      final reference = input.spentTransactionOutput;
      final output = transaction.outputs[i];
      final expectedHash = sha256.convert(utf8.encode(input.challenge.script));
      if (!(output.spendChallengeHash.hash == expectedHash.bytes)) {
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

  bool txoIsSpendable(TransactionOutputReference reference) =>
      _utxos[reference.transactionId]?.contains(reference.index) ?? false;

  Map<TransactionId, Set<int>> get utxos => _utxos;

  Future<bool> executeScript(String script, List<List<int>> arguments) async {
    // TODO
    return true;
  }
}
