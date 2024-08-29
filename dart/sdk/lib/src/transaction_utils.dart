import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';

import 'package:blockchain_protobuf/google/protobuf/struct.pb.dart' as struct;

extension TransactionOps on Transaction {
  Future<Set<LockAddress>> requiredWitnesses(
      Future<TransactionOutput> Function(TransactionOutputReference)
          fetchTransactionOutput) async {
    final result = <LockAddress>{};
    for (final input in inputs) {
      final out = await fetchTransactionOutput(input.reference);
      result.add(out.lockAddress);
    }
    for (final output in outputs) {
      if (output.value.hasGraphEntry() && output.value.graphEntry.hasEdge()) {
        final edge = output.value.graphEntry.edge;
        final TransactionOutput aTxO;
        if (edge.a.hasTransactionId()) {
          aTxO = await fetchTransactionOutput(edge.a);
        } else {
          aTxO = outputs[edge.a.index];
        }
        final aVertex = aTxO.value.ensureGraphEntry().vertex;
        if (aVertex.hasEdgeLockAddress()) {
          result.add(aVertex.edgeLockAddress);
        }

        final TransactionOutput bTxO;
        if (edge.b.hasTransactionId()) {
          bTxO = await fetchTransactionOutput(edge.b);
        } else {
          bTxO = outputs[edge.b.index];
        }
        final bVertex = bTxO.value.ensureGraphEntry().vertex;
        if (bVertex.hasEdgeLockAddress()) {
          result.add(bVertex.edgeLockAddress);
        }
      }
      if (output.hasAccount()) {
        final TransactionOutput accountTxO;
        if (output.account.hasTransactionId()) {
          accountTxO = await fetchTransactionOutput(output.account);
        } else {
          accountTxO = outputs[output.account.index];
        }
        result.add(accountTxO.lockAddress);
      }
    }
    return result;
  }

  Int64 get inputSum =>
      inputs.fold(Int64.ZERO, (a, input) => a + input.value.quantity);
  Int64 get outputSum =>
      outputs.fold(Int64.ZERO, (a, input) => a + input.value.quantity);
  Int64 get reward => inputSum - outputSum;
}

extension TransactionOutputOps on TransactionOutput {
  bool get isPaymentToken =>
      !value.hasGraphEntry() &&
      !hasAccount() &&
      !value.hasAccountRegistration();

  Int64 get requiredMinimumQuantity {
    Int64 result = Int64.ZERO;
    result += 100; // Dust prevention
    if (hasAccount()) {
      result += 50; // Adding to existing staking account
    }
    if (value.hasAccountRegistration()) {
      result += 1000; // Creating a new staking account
    }
    if (value.hasGraphEntry()) {
      result += graphEntryMinimumQuantity(value.graphEntry);
    }
    return result;
  }
}

Int64 graphEntryMinimumQuantity(GraphEntry graphEntry) {
  Int64 result = Int64.ZERO;
  if (graphEntry.hasVertex()) {
    final vertex = graphEntry.vertex;
    result += vertex.label.length * 10;
    if (vertex.hasData()) {
      result += protoStructMinimumQuantity(vertex.data);
    }
  } else if (graphEntry.hasEdge()) {
    final edge = graphEntry.edge;
    result += edge.label.length * 10;
    result += 100;
    if (edge.hasData()) {
      result += protoStructMinimumQuantity(edge.data);
    }
  }
  return result;
}

Int64 protoValueMinimumQuantity(struct.Value value) {
  if (value.hasStringValue()) {
    final stringValue = value.stringValue;
    return Int64(stringValue.length * 10);
  } else if (value.hasNumberValue()) {
    final numberValue = value.numberValue;
    return Int64(numberValue.toString().length * 10);
  } else if (value.hasBoolValue()) {
    return Int64(10);
  } else if (value.hasListValue()) {
    final listValue = value.listValue;
    return listValue.values.fold<Int64>(
        Int64.ZERO, (sum, value) => sum + protoValueMinimumQuantity(value));
  } else if (value.hasStructValue()) {
    final structValue = value.structValue;
    return protoStructMinimumQuantity(structValue);
  } else {
    return Int64(10);
  }
}

Int64 protoStructMinimumQuantity(struct.Struct struct) {
  return struct.fields.entries.fold<Int64>(Int64.ZERO, (sum, entry) {
    final fieldName = entry.key;
    final fieldValue = entry.value;
    return sum +
        Int64(fieldName.length * 10) +
        protoValueMinimumQuantity(fieldValue);
  });
}

final defaultTransactionTip = Int64(1000);

extension FullBodyOps on FullBlockBody {
  Transaction? get rewardTransaction => transactions
      .map<Transaction?>((t) => t)
      .firstWhere((t) => t?.hasRewardParentBlockId() ?? false,
          orElse: () => null);
}

extension TransactionOutputReferenceOps on TransactionOutputReference {
  TransactionOutputReference withoutSelfReference(
          TransactionId selfTransactionId) =>
      hasTransactionId()
          ? this
          : TransactionOutputReference(
              transactionId: selfTransactionId, index: index);
}
