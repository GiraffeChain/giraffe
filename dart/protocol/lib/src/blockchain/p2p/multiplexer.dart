import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:async_queue/async_queue.dart';
import 'package:fixnum/fixnum.dart';
import '../blockchain.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:mutex/mutex.dart';

typedef PortId = int;

class MultiplexedReaderWriter {
  final Stream<(PortId, Uint8List)> read;
  final void Function(PortId, Uint8List) write;

  MultiplexedReaderWriter({required this.read, required this.write});

  factory MultiplexedReaderWriter.forChunkedReader(
      ChunkedStreamReader<int> reader, Function(List<int>) writer) {
    final r = _extractReader(reader);
    write(PortId port, Uint8List data) {
      writer([
        ...Int32(port).toBytesBigEndian(),
        ...Int32(data.length).toBytesBigEndian(),
        ...data
      ]);
    }

    return MultiplexedReaderWriter(read: r, write: write);
  }

  static Stream<(PortId, Uint8List)> _extractReader(
      ChunkedStreamReader<int> reader) async* {
    while (true) {
      final prefix = await reader.readBytesOpt(8);
      if (prefix == null) return;
      // TODO: Compare with Ints.fromBytes
      final port = prefix.sublist(0, 4).buffer.asByteData().getUint32(0);
      final length = prefix.sublist(4, 8).buffer.asByteData().getUint32(0);
      final data = await reader.readBytesOpt(length);
      if (data == null) {
        return;
      }
      yield (port, data);
    }
  }
}

class MultiplexerPort<Request, Response> {
  final int port;
  final Future<Response> Function(Request) requestHandler;
  final MultiplexedReaderWriter readerWriter;
  final P2PCodec<Request> requestCodec;
  final P2PCodec<Response> responseCodec;

  final AsyncQueue _requestQueue = AsyncQueue.autoStart();
  final Queue<Completer<Response>> _responses = Queue();
  final Mutex _mutex = Mutex();

  MultiplexerPort({
    required this.port,
    required this.requestHandler,
    required this.readerWriter,
    required this.requestCodec,
    required this.responseCodec,
  });

  void processRequest(Uint8List data) async {
    final request = requestCodec.decoder(data);
    _requestQueue.addJob((_) async {
      final response = await requestHandler(request);
      final encoded =
          Uint8List.fromList([1, ...responseCodec.encoder(response)]);
      readerWriter.write(port, encoded);
    });
  }

  void processResponse(Uint8List data) {
    if (_responses.isEmpty) {
      throw Exception('No response to process');
    }
    final response = responseCodec.decoder(data);
    _responses.removeFirst().complete(response);
  }

  Future<Response> request(Request request) async {
    final encoded = Uint8List.fromList([0, ...requestCodec.encoder(request)]);
    return await _expectResponse(() async => readerWriter.write(port, encoded));
  }

  void close() {
    while (_responses.isNotEmpty) {
      _responses.removeFirst().completeError(Exception('Port closed'));
    }
    _requestQueue.close();
    _requestQueue.clear();
  }

  Future<Response> _expectResponse(Future<void> Function() innerEffect) async {
    final Future<Response> future =
        await _mutex.protect<Future<Response>>(() async {
      final completer = Completer<Response>();
      _responses.add(completer);
      await innerEffect();
      return completer.future;
    });
    return future;
  }
}

class MultiplexerPorts {
  final MultiplexerPort<void, PublicP2PState> p2pState;
  final MultiplexerPort<void, BlockId> blockAdoptions;
  final MultiplexerPort<void, TransactionId> transactionAdoptions;
  final MultiplexerPort<Uint8List, Uint8List> pingPong;
  final MultiplexerPort<Int64, BlockId?> blockIdAtHeight;
  final MultiplexerPort<BlockId, BlockHeader?> headers;
  final MultiplexerPort<BlockId, BlockBody?> bodies;
  final MultiplexerPort<TransactionId, Transaction?> transactions;
  late final Map<int, MultiplexerPort> _asMap;

  MultiplexerPorts(
      {required this.p2pState,
      required this.blockAdoptions,
      required this.transactionAdoptions,
      required this.pingPong,
      required this.blockIdAtHeight,
      required this.headers,
      required this.bodies,
      required this.transactions}) {
    _asMap = {
      p2pState.port: p2pState,
      blockAdoptions.port: blockAdoptions,
      transactionAdoptions.port: transactionAdoptions,
      pingPong.port: pingPong,
      blockIdAtHeight.port: blockIdAtHeight,
      headers.port: headers,
      bodies.port: bodies,
      transactions.port: transactions,
    };
  }

  static Future<MultiplexerPorts> create(
      MultiplexedReaderWriter readerWriter,
      Future<PublicP2PState> Function() currentState,
      BlockchainCore core) async {
    return MultiplexerPorts(
      p2pState: MultiplexerPort(
        port: PortIds.peerStateRequest,
        requestHandler: (_) => currentState(),
        readerWriter: readerWriter,
        requestCodec: P2PCodecs.voidCodec,
        responseCodec: P2PCodecs.publicP2PStateCodec,
      ),
      blockAdoptions: MultiplexerPort(
        port: PortIds.blockAdoptionRequest,
        requestHandler: (_) => core.consensus.localChain.adoptions.first,
        readerWriter: readerWriter,
        requestCodec: P2PCodecs.voidCodec,
        responseCodec: P2PCodecs.blockIdCodec,
      ),
      transactionAdoptions: MultiplexerPort(
        port: PortIds.transactionAdoptionRequest,
        requestHandler: (_) async => Future.delayed(
            Duration(days: 365), () async => throw UnimplementedError()),
        readerWriter: readerWriter,
        requestCodec: P2PCodecs.voidCodec,
        responseCodec: P2PCodecs.transactionIdCodec,
      ),
      pingPong: MultiplexerPort(
        port: PortIds.pingRequest,
        requestHandler: (v) async => v,
        readerWriter: readerWriter,
        requestCodec: P2PCodecs.bytesCodec,
        responseCodec: P2PCodecs.bytesCodec,
      ),
      blockIdAtHeight: MultiplexerPort(
        port: PortIds.blockIdAtHeightRequest,
        requestHandler: core.consensus.localChain.blockIdAtHeight,
        readerWriter: readerWriter,
        requestCodec: P2PCodecs.heightCodec,
        responseCodec: P2PCodecs.blockIdOptCodec,
      ),
      headers: MultiplexerPort(
        port: PortIds.headerRequest,
        requestHandler: core.dataStores.headers.get,
        readerWriter: readerWriter,
        requestCodec: P2PCodecs.blockIdCodec,
        responseCodec: P2PCodecs.headerOptCodec,
      ),
      bodies: MultiplexerPort(
        port: PortIds.bodyRequest,
        requestHandler: core.dataStores.bodies.get,
        readerWriter: readerWriter,
        requestCodec: P2PCodecs.blockIdCodec,
        responseCodec: P2PCodecs.bodyOptCodec,
      ),
      transactions: MultiplexerPort(
        port: PortIds.transactionRequest,
        requestHandler: core.dataStores.transactions.get,
        readerWriter: readerWriter,
        requestCodec: P2PCodecs.transactionIdCodec,
        responseCodec: P2PCodecs.transactionOptCodec,
      ),
    );
  }

  void processRequest(int port, Uint8List data) {
    final h = _asMap[port];
    if (h == null) {
      throw ArgumentError.value(port, "port");
    }
    h.processRequest(data);
  }

  void processResponse(int port, Uint8List data) {
    final h = _asMap[port];
    if (h == null) {
      throw ArgumentError.value(port, "port");
    }
    h.processResponse(data);
  }

  Stream<void> background(MultiplexedReaderWriter readerWriter) {
    return readerWriter.read.map((r) {
      final (port, bytes) = r;
      assert(bytes.isNotEmpty);
      switch (bytes[0]) {
        case 0:
          return processRequest(port, bytes.sublist(1));
        case 1:
          return processResponse(port, bytes.sublist(1));
        default:
          throw Exception('Invalid message type');
      }
    });
  }

  void close() {
    for (final port in _asMap.values) {
      port.close();
    }
  }
}

class PortIds {
  static const blockIdAtHeightRequest = 10;
  static const headerRequest = 11;
  static const bodyRequest = 12;
  static const blockAdoptionRequest = 13;
  static const transactionRequest = 14;
  static const transactionAdoptionRequest = 15;
  static const peerStateRequest = 16;
  static const pingRequest = 17;
}
