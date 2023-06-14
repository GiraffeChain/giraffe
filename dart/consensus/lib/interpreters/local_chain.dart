import 'dart:async';

import 'package:blockchain_consensus/algebras/local_chain_algebra.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

class LocalChain extends LocalChainAlgebra {
  LocalChain(BlockId initialHead) : this._currentHead = initialHead;
  BlockId _currentHead;

  final StreamController<BlockId> _streamController =
      StreamController.broadcast();

  @override
  Future<void> adopt(BlockId newHead) async {
    if (_currentHead != newHead) {
      _currentHead = newHead;
      _streamController.add(newHead);
    }
  }

  @override
  Stream<BlockId> get adoptions => _streamController.stream;

  @override
  Future<BlockId> get currentHead => Future.sync(() => _currentHead);
}
