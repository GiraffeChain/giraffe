import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:giraffe_sdk/sdk.dart';

import 'multiplexer.dart';

abstract class PeerBlockchainInterface {
  Future<PublicP2PState> publicState();
  Future<BlockId> nextBlockAdoption();
  Future<TransactionId> nextTransactionNotification();
  Future<BlockHeader?> fetchHeader(BlockId id);
  Future<BlockBody?> fetchBody(BlockId id);
  Future<Transaction?> fetchTransaction(TransactionId id);
  Future<BlockId?> blockIdAtHeight(Int64 height);
  Future<Uint8List> ping(Uint8List message);
  Future<BlockId> commonAncestor();
}

class PeerBlockchainInterfaceImpl extends PeerBlockchainInterface {
  final MultiplexerPorts ports;

  PeerBlockchainInterfaceImpl({required this.ports});

  @override
  Future<BlockId?> blockIdAtHeight(Int64 height) =>
      ports.blockIdAtHeight.request(height).timeout(defaultReadTimeout);

  @override
  Future<BlockId> commonAncestor() {
    throw UnimplementedError();
  }

  @override
  Future<BlockBody?> fetchBody(BlockId id) =>
      ports.bodies.request(id).timeout(defaultReadTimeout);

  @override
  Future<BlockHeader?> fetchHeader(BlockId id) =>
      ports.headers.request(id).timeout(defaultReadTimeout);

  @override
  Future<Transaction?> fetchTransaction(TransactionId id) =>
      ports.transactions.request(id).timeout(defaultReadTimeout);

  @override
  Future<BlockId> nextBlockAdoption() => ports.blockAdoptions.request(null);

  @override
  Future<TransactionId> nextTransactionNotification() =>
      ports.transactionAdoptions.request(null);

  @override
  Future<Uint8List> ping(Uint8List message) =>
      ports.pingPong.request(message).timeout(defaultReadTimeout);

  @override
  Future<PublicP2PState> publicState() =>
      ports.p2pState.request(null).timeout(defaultReadTimeout);
}

const defaultReadTimeout = Duration(seconds: 5);
