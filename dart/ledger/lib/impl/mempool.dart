import 'package:blockchain_codecs/codecs.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

class Mempool {
  final Map<TransactionId, MempoolEntry> _entries = {};
  final Set<TransactionId> _heads = {};

  Future<void> add(Transaction transaction) async {
    final id = transaction.id;
    if (_entries.containsKey(id)) return;
    bool isHead = true;
    for (final input in transaction.inputs) {
      final parent = _entries[input.reference.transactionId];
      if (parent != null) {
        parent.descendents.add(id);
        isHead = false;
      }
    }
    final entry = MempoolEntry(id, {});
    _entries[id] = entry;
    if (isHead) {
      _heads.add(id);
    }
  }
}

class MempoolEntry {
  final TransactionId id;
  final Set<TransactionId> descendents;

  MempoolEntry(this.id, this.descendents);
}
