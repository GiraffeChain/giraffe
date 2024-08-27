import 'dart:convert';

import 'package:blockchain_sdk/sdk.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_sdk/src/http/http_client.dart';
import 'package:fixnum/fixnum.dart';
import 'package:rxdart/transformers.dart';
import 'package:http/http.dart' as http;

abstract class BlockchainClient {
  Future<BlockHeader?> getBlockHeader(BlockId blockId);
  Future<BlockBody?> getBlockBody(BlockId blockId);
  Future<Transaction?> getTransaction(TransactionId transactionId);
  Future<TransactionOutput?> getTransactionOutput(
      TransactionOutputReference reference);
  Future<BlockId?> getBlockIdAtHeight(Int64 height);
  Future<BlockId> get canonicalHeadId =>
      getBlockIdAtHeight(Int64.ZERO).then((v) => v!);
  Future<BlockId> get genesisBlockId =>
      getBlockIdAtHeight(Int64.ONE).then((v) => v!);
  Future<List<TransactionOutputReference>> getLockAddressState(
      LockAddress lock);
  Future<List<TransactionOutputReference>> queryVertices(
      String label, List<WhereClause> where);
  Future<List<TransactionOutputReference>> queryEdges(
      String label,
      TransactionOutputReference? a,
      TransactionOutputReference? b,
      List<WhereClause> where);
  Future<List<TransactionOutputReference>> inEdges(
      TransactionOutputReference vertex);
  Future<List<TransactionOutputReference>> outEdges(
      TransactionOutputReference vertex);
  Future<List<TransactionOutputReference>> edges(
      TransactionOutputReference vertex);

  Stream<TraversalStep> get traversal;

  Future<void> broadcastTransaction(Transaction transaction);

  Future<void> broadcastBlock(Block block, Transaction? reward);

  Future<ActiveStaker?> getStaker(
      BlockId parentBlockId, Int64 slot, TransactionOutputReference account);

  Future<Int64> getTotalActivestake(BlockId parentBlockId, Int64 slot);

  Future<List<int>> calculateEta(BlockId parentBlockId, Int64 slot);

  Stream<BlockBody> get packBlock;

  Stream<BlockId> get adoptions =>
      traversal.whereType<TraversalStep_Applied>().map((t) => t.blockId);

  Future<BlockHeader> getBlockHeaderOrRaise(BlockId blockId) =>
      getBlockHeader(blockId).then((v) => v!);

  Future<BlockBody> getBlockBodyOrRaise(BlockId blockId) =>
      getBlockBody(blockId).then((v) => v!);

  Future<Transaction> getTransactionOrRaise(TransactionId transactionId) =>
      getTransaction(transactionId).then((v) => v!);

  Future<TransactionOutput> getTransactionOutputOrRaise(
          TransactionOutputReference ref) =>
      getTransactionOutput(ref).then((v) => v!);

  Future<FullBlock?> getFullBlock(BlockId blockId) async {
    final header = await getBlockHeader(blockId);
    if (header == null) return null;
    final body = await getBlockBody(blockId);
    if (body == null) return null;
    final transactionsResult = <Transaction>[];
    for (final transactionId in body.transactionIds) {
      final transaction = await getTransaction(transactionId);
      if (transaction == null) return null;
      transactionsResult.add(transaction);
    }
    final fullBody = FullBlockBody(transactions: transactionsResult);
    return FullBlock(header: header, fullBody: fullBody);
  }

  Future<FullBlock> getFullBlockOrRaise(BlockId blockId) =>
      getFullBlock(blockId).then((v) => v!);

  Future<BlockHeader> get genesisHeader =>
      genesisBlockId.then(getBlockHeaderOrRaise);

  Future<FullBlock> get genesisBlock =>
      genesisBlockId.then(getFullBlockOrRaise);

  Future<ProtocolSettings> get protocolSettings async {
    final genesis = await genesisBlock;
    return ProtocolSettings.defaultSettings
        .mergeFromMap(genesis.header.settings);
  }

  Stream<FullBlock> get adoptedBlocks =>
      adoptions.asyncMap(getFullBlock).whereNotNull();

  Future<BlockHeader> get canonicalHead async =>
      getBlockHeaderOrRaise(await canonicalHeadId);
}

class BlockchainClientFromJsonRpc extends BlockchainClient {
  final String baseAddress;

  BlockchainClientFromJsonRpc({required this.baseAddress});

  Map<String, String> get headers {
    final base = <String, String>{};
    base.addAll(corsHeaders);
    return base;
  }

  @override
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
  Future<void> broadcastTransaction(Transaction transaction) async {
    final response = await httpClient.post(
      Uri.parse("$baseAddress/transactions"),
      headers: headers,
      body: utf8.encode(json.encode(transaction.toProto3Json())),
    );
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
  }

  @override
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

  @override
  Future<List<int>> calculateEta(BlockId parentBlockId, Int64 slot) async {
    final response = await httpClient.get(
      Uri.parse("$baseAddress/eta/${parentBlockId.show}/${slot}"),
      headers: headers,
    );
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
    return (json.decode(utf8.decode(response.bodyBytes))["eta"] as String)
        .decodeBase58;
  }

  @override
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

  @override
  Future<Int64> getTotalActivestake(BlockId parentBlockId, Int64 slot) async {
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

  @override
  Stream<BlockBody> get packBlock {
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

  @override
  Future<List<TransactionOutputReference>> edges(
      TransactionOutputReference vertex) async {
    final response = await httpClient.get(
      Uri.parse(
          "$baseAddress/graph/${vertex.transactionId.show}/${vertex.index}/edges"),
      headers: headers,
    );
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
    final items = json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return items
        .map((e) => TransactionOutputReference()..mergeFromProto3Json(e))
        .toList();
  }

  @override
  Future<List<TransactionOutputReference>> inEdges(
      TransactionOutputReference vertex) async {
    final response = await httpClient.get(
      Uri.parse(
          "$baseAddress/graph/${vertex.transactionId.show}/${vertex.index}/in-edges"),
      headers: headers,
    );
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
    final items = json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return items
        .map((e) => TransactionOutputReference()..mergeFromProto3Json(e))
        .toList();
  }

  @override
  Future<List<TransactionOutputReference>> outEdges(
      TransactionOutputReference vertex) async {
    final response = await httpClient.get(
      Uri.parse(
          "$baseAddress/graph/${vertex.transactionId.show}/${vertex.index}/out-edges"),
      headers: headers,
    );
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
    final items = json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return items
        .map((e) => TransactionOutputReference()..mergeFromProto3Json(e))
        .toList();
  }

  @override
  Future<List<TransactionOutputReference>> queryEdges(
      String label,
      TransactionOutputReference? a,
      TransactionOutputReference? b,
      List<WhereClause> where) async {
    final bodyJson = {
      "label": label,
      "a": a?.show,
      "b": b?.show,
      "where": where.map((e) => e.toJson()).toList(),
    };
    final response = await httpClient.post(
      Uri.parse("$baseAddress/graph/query-edges"),
      headers: headers,
      body: utf8.encode(json.encode(bodyJson)),
    );
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
    final items = json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return items
        .map((e) => TransactionOutputReference()..mergeFromProto3Json(e))
        .toList();
  }

  @override
  Future<List<TransactionOutputReference>> queryVertices(
      String label, List<WhereClause> where) async {
    final bodyJson = {
      "label": label,
      "where": where.map((e) => e.toJson()).toList(),
    };
    final response = await httpClient.post(
      Uri.parse("$baseAddress/graph/query-vertices"),
      headers: headers,
      body: utf8.encode(json.encode(bodyJson)),
    );
    assert(response.statusCode == 200, "HTTP Error: ${response.body}");
    final items = json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return items
        .map((e) => TransactionOutputReference()..mergeFromProto3Json(e))
        .toList();
  }
}

class WhereClause {
  final String key;
  final String operand;
  final dynamic value;

  WhereClause(this.key, this.operand, this.value);

  List<dynamic> toJson() => [key, operand, value];
}
