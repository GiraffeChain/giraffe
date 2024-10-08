import 'dart:async';
import 'dart:collection';

import 'package:fixnum/fixnum.dart';
import 'package:giraffe_protocol/protocol.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:logging/logging.dart';
import 'package:mutex/mutex.dart';

import 'peer_handler.dart';

class SharedSync {
  final BlockchainCore core;
  final Map<PeerId, PeerBlockchainInterface> Function() clientsF;
  SharedSyncState? _state;
  final mutex = Mutex();

  SharedSync({required this.core, required this.clientsF});

  Future<void> compare(
          BlockHeader commonAncestor, BlockHeader target, PeerId peerId) =>
      mutex.protect(() async {
        if (_state == null) {
          return localCompare(commonAncestor, target, peerId);
        } else if (_state!.target.id == target.id ||
            _state!.target.id == target.parentHeaderId) {
          return updateTarget(commonAncestor, target, peerId);
        } else {
          return remoteCompare(target, peerId, _state!);
        }
      });

  Future<void> omitPeer(PeerId peerId) async {
    if (_state != null) {
      if (_state!.providers.length == 1 && _state!.providers.contains(peerId)) {
        await _state!.cancel();
        _state = null;
      } else {
        _state!.providers.remove(peerId);
      }
    }
  }

  Future<void> syncCompletion() async {
    if (_state != null) {
      await _state!.result;
      _state = null;
    }
  }

  Future<void> localCompare(
      BlockHeader commonAncestor, BlockHeader target, PeerId peerId) async {
    final clients = clientsF();
    final interface = clients[peerId];
    if (interface == null) {
      throw StateError("Peer not found");
    }
    final localHeader = await core.dataStores.headers
        .getOrRaise(core.consensus.localChain.head);

    Future<BlockHeader?> localHeaderAtHeight(Int64 height) async {
      final id = await core.consensus.localChain.blockIdAtHeight(height);
      if (id != null) {
        return await core.dataStores.headers.getOrRaise(id);
      }
      return null;
    }

    final chainSelectionResult = await core.consensus.chainSelection.compare(
      localHeader,
      target,
      commonAncestor,
      localHeaderAtHeight,
      interface.fetchHeaderAtHeight,
    );
    if (chainSelectionResult.isY) {
      await updateTarget(commonAncestor, target, peerId);
    }
  }

  Future<void> remoteCompare(
      BlockHeader target, PeerId peerId, SharedSyncState state) async {
    final clients = clientsF();
    final interface = clients[peerId];
    if (interface == null) {
      throw StateError("Peer not found");
    }
    final localInterface = SortedPeerInterface(clients.values);
    final commonAncestor = await interface.commonAncestor();
    final commonAncestorHeader = await interface.fetchHeader(commonAncestor);

    if (commonAncestorHeader == null) {
      throw StateError("Common ancestor not found");
    }

    final chainSelectionResult = await core.consensus.chainSelection.compare(
      state.target,
      target,
      commonAncestorHeader,
      localInterface.fetchHeaderAtHeight,
      interface.fetchHeaderAtHeight,
    );
    if (chainSelectionResult.isY) {
      await updateTarget(commonAncestorHeader, target, peerId);
    }
  }

  Future<void> updateTarget(
      BlockHeader commonAncestor, BlockHeader target, PeerId provider) async {
    if (_state != null) {
      final state = _state!;
      if (state.target.id == target.id) {
        log.info("Adding provider=${provider.show} to existing sync");
        state.providers.add(provider);
      } else if (state.target.id == target.parentHeaderId) {
        log.info(
            "Retargetting extension of current sync from provider=${provider.show}");
        state.target = target;
        state.providers
          ..clear()
          ..add(provider);
      } else {
        log.info("Canceling current sync");
        await state.cancel();
        _state = null;
        sync(commonAncestor, target, provider);
      }
    } else {
      sync(commonAncestor, target, provider);
    }
  }

  void sync(BlockHeader commonAncestor, BlockHeader target, PeerId provider) {
    log.info(
        "Starting sync to target=${target.id.show} provider=${provider.show}");
    final completer = Completer<void>();

    Stream<void> stream() async* {
      Int64 height = commonAncestor.height;
      Int64 batchTarget = height + 500;
      if (batchTarget > target.height) batchTarget = target.height;
      while (batchTarget <= _state!.target.height) {
        yield* syncHeights(height, batchTarget);
        height = batchTarget + 1;
        batchTarget += 500;
        if (batchTarget > _state!.target.height) {
          batchTarget = _state!.target.height;
        }
      }
      yield null;
      _state = null;
    }

    final sub = stream().listen((_) {},
        onDone: completer.complete,
        onError: completer.completeError,
        cancelOnError: true);

    cancel() async {
      await sub.cancel();
      completer.complete();
    }

    _state = SharedSyncState(
        target: target,
        providers: {provider},
        result: completer.future,
        cancel: cancel);
  }

  Future<void> close() async {
    if (_state != null) {
      await _state!.cancel();
      _state = null;
    }
  }

  Stream<void> syncHeights(Int64 min, Int64 max) async* {
    final interfaces = await interfacesForHeight(max);
    final interface = SortedPeerInterface(interfaces);
    // TODO: parallelism
    BlockHeader? previous;

    yield* Stream.fromIterable(
            List.generate((max - min).toInt() + 1, (i) => min + i))
        .parAsyncMap(16, interface.blockIdAtHeight)
        .parAsyncMap(32, (blockId) async {
          if (blockId == null) {
            throw StateError("Block not found");
          }
          final BlockHeader header;
          final h = await core.dataStores.headers.get(blockId);
          if (h != null) {
            header = h;
          } else {
            final remoteHeader = await interface.fetchHeader(blockId);
            if (remoteHeader == null) {
              throw StateError("Remote header not found");
            }
            header = remoteHeader;
          }
          return header;
        })
        .asyncMap((header) async {
          if (previous != null && header.parentHeaderId != previous!.id) {
            throw StateError("Fork detected");
          }
          // TODO: Don't double-check local
          await PeerBlockchainHandler.checkHeader(core, header);
          previous = header;
          return header;
        })
        .parAsyncMap(32,
            (header) => PeerBlockchainHandler.fetchFullBlock(interface, header))
        .asyncMap((fullBlock) async {
          await PeerBlockchainHandler.checkBody(core, fullBlock);
        });
    if (previous != null) {
      core.consensus.localChain.adopt(previous!.id);
    }
    yield null;
  }

  Future<List<PeerBlockchainInterface>> interfacesForHeight(
      Int64 height) async {
    final clients = clientsF();
    final providers = _state!.providers;
    final providerInterfaces = providers.toList().map((p) => clients[p]!);
    final providersInterface = SortedPeerInterface(providerInterfaces);
    final batchTargetId = await providersInterface.blockIdAtHeight(height);
    if (batchTargetId == null) {
      throw StateError("Block not found");
    }
    final nonProviderClients = Map.of(clients)
      ..removeWhere((id, _) => providers.contains(id));
    final altClients = [
      for (final c in nonProviderClients.values)
        (await c.blockIdAtHeight(height)) == batchTargetId ? c : null
    ].whereType<PeerBlockchainInterface>();
    return [...providerInterfaces, ...altClients];
  }

  static final log = Logger("SharedSync");
}

class SharedSyncState {
  BlockHeader target;
  final Set<PeerId> providers;
  final Future<void> result;
  final Future<void> Function() cancel;

  SharedSyncState(
      {required this.target,
      required this.providers,
      required this.result,
      required this.cancel});
}

Stream<O> parAsyncMapImpl<I, O>(
    int parallelism, Stream<I> stream, Future<O> Function(I) f) {
  bool running = false;
  bool done = false;
  final queue = Queue<Future<O>>();
  final controller = StreamController<O>();
  checkAndPush() async {
    if (running) return;
    running = true;
    while (queue.isNotEmpty) {
      final future = queue.removeFirst();
      final o = await future;
      controller.add(o);
    }
    if (done) {
      controller.close();
    }
    running = false;
  }

  final sub = stream.asyncMap((i) async {
    if (queue.length >= parallelism) {
      await queue.first;
    }
    queue.add(f(i));
    checkAndPush();
  }).listen((_) {}, cancelOnError: true);
  controller.onCancel = sub.cancel;
  sub.onError(controller.addError);
  sub.onDone(() {
    done = true;
    checkAndPush();
  });
  return controller.stream;
}

extension ParStreamOps<T> on Stream<T> {
  Stream<O> parAsyncMap<O>(int parallelism, Future<O> Function(T) f) =>
      parAsyncMapImpl(parallelism, this, f);
}
