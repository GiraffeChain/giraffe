import 'dart:io';
import 'dart:typed_data';

import 'package:blockchain_protobuf/models/core.pb.dart';

import 'p2p_server.dart';

class BlockchainDataGossipHandler {
  final Socket socket;
  late final DataGossipSocketHandler socketHandler;

  BlockchainDataGossipHandler({
    required this.socket,
    required void Function(BlockId) blockIdNotified,
    required void Function(TransactionId) transactionIdNotified,
    required Future<BlockHeader?> Function(BlockId) fetchLocalHeader,
    required Future<BlockBody?> Function(BlockId) fetchLocalBlockBody,
    required Future<Transaction?> Function(TransactionId) fetchLocalTransaction,
  }) {
    Future<Data?> fulfillRequest(DataRequest request) async {
      switch (request.typeByte) {
        case 10:
          final header = await fetchLocalHeader(BlockId()..value = request.id);
          if (header != null) {
            return Data(request.typeByte, request.id, header.writeToBuffer());
          }
          break;
        case 11:
          final transaction =
              await fetchLocalTransaction(TransactionId()..value = request.id);
          if (transaction != null) {
            return Data(
                request.typeByte, request.id, transaction.writeToBuffer());
          }
          break;
        case 12:
          final body = await fetchLocalBlockBody(BlockId()..value = request.id);
          if (body != null) {
            return Data(request.typeByte, request.id, body.writeToBuffer());
          }
          break;
      }
      return null;
    }

    void notificationReceived(DataNotification notification) {
      switch (notification.typeByte) {
        case 10:
          blockIdNotified(BlockId()..value = notification.id);
          break;
        case 11:
          transactionIdNotified(TransactionId()..value = notification.id);
          break;
      }
    }

    this.socketHandler =
        DataGossipSocketHandler(socket, fulfillRequest, notificationReceived);
  }

  Future<BlockHeader?> requestHeader(BlockId id) async {
    final request = DataRequest(10, Uint8List.fromList(id.value));
    final maybeData = await (socketHandler.requestData(request));
    if (maybeData != null) return BlockHeader.fromBuffer(maybeData.data);
    return null;
  }

  Future<BlockBody?> requestBody(BlockId id) async {
    final request = DataRequest(12, Uint8List.fromList(id.value));
    final maybeData = await (socketHandler.requestData(request));
    if (maybeData != null) return BlockBody.fromBuffer(maybeData.data);
    return null;
  }

  Future<Transaction?> requestTransaction(TransactionId id) async {
    final request = DataRequest(11, Uint8List.fromList(id.value));
    final maybeData = await (socketHandler.requestData(request));
    if (maybeData != null) return Transaction.fromBuffer(maybeData.data);
    return null;
  }

  void notifyBlockId(BlockId id) {
    final notification = DataNotification(10, Uint8List.fromList(id.value));
    socketHandler.notifyData(notification);
  }

  void notifyTransactionId(TransactionId id) {
    final notification = DataNotification(11, Uint8List.fromList(id.value));
    socketHandler.notifyData(notification);
  }
}
