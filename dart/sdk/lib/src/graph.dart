import 'package:blockchain_protobuf/google/protobuf/struct.pb.dart' as struct;
import 'package:blockchain_protobuf/models/core.pb.dart';

import 'blockchain_client.dart';
import 'wallet.dart';
import 'codecs.dart';

class Graph {
  final Wallet wallet;
  final BlockchainClient client;

  Graph({required this.wallet, required this.client});

  Future<TransactionOutputReference> createVertex(
      {required String label, GraphData? data}) async {
    final output = TransactionOutput(
        lockAddress: wallet.defaultLockAddress,
        value: Value(
            graphEntry: GraphEntry(
                vertex: Vertex(label: label, data: _convertData(data)))));
    final tx =
        await wallet.payAndAttest(client, Transaction(outputs: [output]));
    tx.embedId();
    final reference =
        TransactionOutputReference(transactionId: tx.id, index: 0);
    await client.broadcastTransaction(tx);
    return reference;
  }

  Future<TransactionOutputReference> createEdge(
      {required String label,
      required TransactionOutputReference a,
      required TransactionOutputReference b,
      GraphData? data}) async {
    final output = TransactionOutput(
        lockAddress: wallet.defaultLockAddress,
        value: Value(
            graphEntry: GraphEntry(
                edge:
                    Edge(a: a, b: b, label: label, data: _convertData(data)))));
    final tx =
        await wallet.payAndAttest(client, Transaction(outputs: [output]));
    tx.embedId();
    final reference =
        TransactionOutputReference(transactionId: tx.id, index: 0);
    await client.broadcastTransaction(tx);
    return reference;
  }

  List<TransactionOutputReference> get localVertices =>
      wallet.spendableOutputs.entries
          .where((e) => e.value.value.hasGraphEntry())
          .map((e) => e.key)
          .toList();

  List<TransactionOutputReference> get localEdges =>
      wallet.spendableOutputs.entries
          .where((e) => e.value.value.hasGraphEntry())
          .map((e) => e.key)
          .toList();

  struct.Struct? _convertData(GraphData? data) {
    if (data == null) {
      return null;
    }
    final fields = Map.fromEntries(data.entries
        .map((entry) => MapEntry(entry.key, _convertValue(entry.value))));
    return struct.Struct(fields: fields);
  }

  struct.Value _convertValue(value) {
    if (value is String) {
      return struct.Value(stringValue: value);
    } else if (value is int) {
      return struct.Value(numberValue: value.toDouble());
    } else if (value is double) {
      return struct.Value(numberValue: value);
    } else if (value is bool) {
      return struct.Value(boolValue: value);
    } else if (value is List) {
      return struct.Value(
          listValue:
              struct.ListValue(values: value.map(_convertValue).toList()));
    } else if (value is Map) {
      return struct.Value(
          structValue: _convertData(value.cast<String, dynamic>()));
    }

    throw new ArgumentError.value(value, 'value', 'Unsupported type');
  }
}

typedef GraphData = Map<String, dynamic>;
