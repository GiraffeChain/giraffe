import 'dart:convert';
import 'dart:async';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:blockchain_sdk/src/codecs.dart';
import 'package:fixnum/fixnum.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';
import './http_client.dart';

class JsonRpcClient {
  final String baseAddress;

  JsonRpcClient({required this.baseAddress});

  Map<String, String> get headers {
    final base = <String, String>{};
    base.addAll(corsHeaders);
    return base;
  }

  Future<BlockHeader?> getBlockHeader(BlockId id) async {
    final response = await httpClient.post(
      Uri.parse("$baseAddress/block-headers/${id.show}"),
      headers: headers,
    );
    if (response.statusCode == 404) return null;
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
    return BlockHeader.fromJson(utf8.decode(response.bodyBytes));
  }

  Future<BlockBody?> getBlockBody(BlockId id) async {
    final response = await httpClient.post(
      Uri.parse("$baseAddress/block-bodies/${id.show}"),
      headers: headers,
    );
    if (response.statusCode == 404) return null;
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
    return BlockBody.fromJson(utf8.decode(response.bodyBytes));
  }

  Future<FullBlock?> getFullBlock(BlockId id) async {
    final response = await httpClient.post(
      Uri.parse("$baseAddress/blocks/${id.show}"),
      headers: headers,
    );
    if (response.statusCode == 404) return null;
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
    return FullBlock.fromJson(utf8.decode(response.bodyBytes));
  }

  Future<Transaction?> getTransaction(TransactionId id) async {
    final response = await httpClient.post(
      Uri.parse("$baseAddress/transactions/${id.show}"),
      headers: headers,
    );
    if (response.statusCode == 404) return null;
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
    return Transaction.fromJson(utf8.decode(response.bodyBytes));
  }

  Future<BlockId?> getBlockIdAtHeight(Int64 height) async {
    final response = await httpClient.post(
      Uri.parse("$baseAddress/block-ids/${height}"),
      headers: headers,
    );
    if (response.statusCode == 404) return null;
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
    return decodeBlockId(
        json.decode(utf8.decode(response.bodyBytes))["blockId"] as String);
  }

  Stream<TraversalStep> get traversal {
    final client = makeHttpClient();
    Future<Stream<List<int>>> call() async {
      final request = http.Request("POST", Uri.parse("$baseAddress/follow"))
        ..persistentConnection = false
        ..headers.addAll(headers);
      final response = await client.send(request);
      assert(response.statusCode == 200);
      return response.stream;
    }

    return Stream.fromFuture(call())
        .asyncExpand((stream) => stream)
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .where((line) => line.isNotEmpty)
        .map((line) {
          final decoded = json.decode(line);
          if (decoded["applied"] != null) {
            return TraversalStep_Applied(
                BlockId()..value = decoded["applied"] as String);
          } else {
            return TraversalStep_Unapplied(
                BlockId()..value = decoded["unapplied"] as String);
          }
        })
        .doOnCancel(() => client.close())
        .doOnDone(() => client.close())
        .doOnError((_, __) => client.close());
  }

  Future<List<TransactionOutputReference>> getLockAddressState(
      LockAddress lock) async {
    final response = await httpClient.post(
      Uri.parse("$baseAddress/lock-addresses/${lock.show}"),
      headers: headers,
    );
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
    return (json.decode(utf8.decode(response.bodyBytes)) as List)
        .map((e) => TransactionOutputReference.fromJson(e))
        .toList();
  }

  Future<List<TransactionOutput>> getAccountState(
      TransactionOutputReference account) async {
    final response = await httpClient.post(
      Uri.parse(
          "$baseAddress/account-states/${account.transactionId.show}/${account.index}"),
      headers: headers,
    );
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
    return (json.decode(utf8.decode(response.bodyBytes)) as List)
        .map((e) => TransactionOutput.fromJson(e))
        .toList();
  }

  Future<TransactionOutput?> getTransactionOutput(
      TransactionOutputReference reference) async {
    final response = await httpClient.post(
      Uri.parse(
          "$baseAddress/transaction-outputs/${reference.transactionId.show}/${reference.index}"),
      headers: headers,
    );
    if (response.statusCode == 404) return null;
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
    return TransactionOutput.fromJson(utf8.decode(response.bodyBytes));
  }
}
