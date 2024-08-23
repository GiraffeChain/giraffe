import 'dart:convert';
import 'dart:async';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_sdk/src/codecs.dart';
import 'package:fixnum/fixnum.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';
import '../traversal.dart';
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
    final response = await httpClient.get(
      Uri.parse("$baseAddress/block-headers/${id.show}"),
      headers: headers,
    );
    if (response.statusCode == 404) return null;
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
    return BlockHeader()
      ..mergeFromProto3Json(json.decode(utf8.decode(response.bodyBytes)));
  }

  Future<BlockBody?> getBlockBody(BlockId id) async {
    final response = await httpClient.get(
      Uri.parse("$baseAddress/block-bodies/${id.show}"),
      headers: headers,
    );
    if (response.statusCode == 404) return null;
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
    return BlockBody()
      ..mergeFromProto3Json(json.decode(utf8.decode(response.bodyBytes)));
  }

  Future<FullBlock?> getFullBlock(BlockId id) async {
    final response = await httpClient.get(
      Uri.parse("$baseAddress/blocks/${id.show}"),
      headers: headers,
    );
    if (response.statusCode == 404) return null;
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
    return FullBlock()
      ..mergeFromProto3Json(json.decode(utf8.decode(response.bodyBytes)));
  }

  Future<Transaction?> getTransaction(TransactionId id) async {
    final response = await httpClient.get(
      Uri.parse("$baseAddress/transactions/${id.show}"),
      headers: headers,
    );
    if (response.statusCode == 404) return null;
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
    return Transaction()
      ..mergeFromProto3Json(json.decode(utf8.decode(response.bodyBytes)));
  }

  Future<BlockId?> getBlockIdAtHeight(Int64 height) async {
    final response = await httpClient.get(
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
      final request = http.Request("GET", Uri.parse("$baseAddress/follow"))
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
          if (decoded["adopted"] != null) {
            return TraversalStep_Applied(
                decodeBlockId(decoded["adopted"] as String));
          } else {
            return TraversalStep_Unapplied(
                decodeBlockId(decoded["unadopted"] as String));
          }
        })
        .doOnCancel(() => client.close())
        .doOnDone(() => client.close())
        .doOnError((_, __) => client.close());
  }

  Future<List<TransactionOutputReference>> getLockAddressState(
      LockAddress lock) async {
    final uri = Uri.parse("$baseAddress/address-states/${lock.show}");
    final response = await httpClient.get(
      uri,
      headers: headers,
    );
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
    return (json.decode(utf8.decode(response.bodyBytes)) as List)
        .map((e) => TransactionOutputReference()..mergeFromProto3Json(e))
        .toList();
  }

  Future<List<TransactionOutput>> getAccountState(
      TransactionOutputReference account) async {
    final response = await httpClient.get(
      Uri.parse(
          "$baseAddress/account-states/${account.transactionId.show}/${account.index}"),
      headers: headers,
    );
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
    return (json.decode(utf8.decode(response.bodyBytes)) as List)
        .map((e) => TransactionOutput()..mergeFromProto3Json(e))
        .toList();
  }

  Future<TransactionOutput?> getTransactionOutput(
      TransactionOutputReference reference) async {
    final response = await httpClient.get(
      Uri.parse(
          "$baseAddress/transaction-outputs/${reference.transactionId.show}/${reference.index}"),
      headers: headers,
    );
    if (response.statusCode == 404) return null;
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
    return TransactionOutput()
      ..mergeFromProto3Json(json.decode(utf8.decode(response.bodyBytes)));
  }

  Future<void> broadcastTransaction(Transaction transaction) async {
    final response = await httpClient.post(
      Uri.parse("$baseAddress/transactions"),
      headers: headers,
      body: utf8.encode(json.encode(transaction.toProto3Json())),
    );
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
  }

  Future<void> broadcastBlock(Block block, Transaction? reward) async {
    final body = <String, dynamic>{
      "block": block.toProto3Json(),
      "reward": reward?.toProto3Json(),
    };
    final response = await httpClient.post(
      Uri.parse("$baseAddress/blocks"),
      headers: headers,
      body: utf8.encode(json.encode(body)),
    );
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
  }

  Future<ActiveStaker?> getStaker(BlockId parentBlockId, Int64 slot,
      TransactionOutputReference account) async {
    final response = await httpClient.get(
      Uri.parse(
          "$baseAddress/stakers/${parentBlockId.show}/${slot}/${account.transactionId.show}/${account.index}"),
      headers: headers,
    );
    if (response.statusCode == 404) return null;
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
    return ActiveStaker()
      ..mergeFromProto3Json(json.decode(utf8.decode(response.bodyBytes)));
  }

  Future<Int64> totalActiveStake(BlockId parentBlockId, Int64 slot) async {
    final response = await httpClient.get(
      Uri.parse(
          "$baseAddress/total-active-stake/${parentBlockId.show}/${slot}"),
      headers: headers,
    );
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
    return Int64(
        json.decode(utf8.decode(response.bodyBytes))["totalActiveStake"]
            as int); // TODO: Backend should send string
  }

  Future<List<int>> getEta(BlockId parentBlockId, Int64 slot) async {
    final response = await httpClient.get(
      Uri.parse("$baseAddress/eta/${parentBlockId.show}/${slot}"),
      headers: headers,
    );
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
    return (json.decode(utf8.decode(response.bodyBytes))["eta"] as String)
        .decodeBase58;
  }

  Stream<BlockBody> get blockPacker {
    final client = makeHttpClient();
    Future<Stream<List<int>>> call() async {
      final request =
          http.Request("GET", Uri.parse("$baseAddress/block-packer"))
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
          return BlockBody()..mergeFromProto3Json(json.decode(line));
        })
        .doOnCancel(() => client.close())
        .doOnDone(() => client.close())
        .doOnError((_, __) => client.close());
  }
}
