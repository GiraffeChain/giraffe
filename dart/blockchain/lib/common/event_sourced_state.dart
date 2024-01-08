import 'package:blockchain/common/parent_child_tree.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain/consensus/local_chain.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mutex/mutex.dart';

abstract class EventSourcedState<State, Id> {
  Future<State> stateAt(Id eventId);
  Future<U> useStateAt<U>(Id eventId, Future<U> Function(State) f);
}

class BlockSourcedState<State> extends EventTreeStateImpl<State, BlockId> {
  BlockSourcedState(super.applyEvent, super.unapplyEvent, super.parentChildTree,
      super.currentState, super.currentEventId, super.currentEventChanged);

  Resource<BackgroundHandler> followChain(LocalChain localChain) =>
      Resource.backgroundStream(
          localChain.adoptions.asyncMap(stateAt).map((_) {}));
}

class EventTreeStateImpl<State, Id> extends EventSourcedState<State, Id> {
  final Future<State> Function(State, Id) applyEvent;
  final Future<State> Function(State, Id) unapplyEvent;
  final ParentChildTree<Id> parentChildTree;
  State currentState;
  Id currentEventId;
  final Future<void> Function(Id) currentEventChanged;
  final _mutex = Mutex();

  EventTreeStateImpl(
    this.applyEvent,
    this.unapplyEvent,
    this.parentChildTree,
    this.currentState,
    this.currentEventId,
    this.currentEventChanged,
  );

  @override
  Future<State> stateAt(eventId) => useStateAt(eventId, (t) => Future.value(t));

  @override
  Future<U> useStateAt<U>(Id eventId, Future<U> Function(State p1) f) {
    return _mutex.protect(() async {
      if (eventId == currentEventId)
        return f(currentState);
      else {
        final applyUnapplyChains =
            await parentChildTree.findCommmonAncestor(currentEventId, eventId);
        await _unapplyEvents(
            applyUnapplyChains.$1.sublist(1), applyUnapplyChains.$1.first);
        await _applyEvents(applyUnapplyChains.$2.sublist(1));
      }
      return f(currentState);
    });
  }

  _unapplyEvents(List<Id> eventIds, Id newEventId) async {
    final indexedEventIds =
        eventIds.mapWithIndex((t, index) => (t, index)).toList().reversed;
    for (final idIndex in indexedEventIds) {
      final newState = await unapplyEvent(currentState, idIndex.$1);
      final nextEventId = idIndex.$2 == 0 ? newEventId : eventIds[idIndex.$2];
      currentState = newState;
      currentEventId = nextEventId;
      await currentEventChanged(nextEventId);
    }
  }

  _applyEvents(Iterable<Id> eventIds) async {
    for (final eventId in eventIds) {
      currentState = await applyEvent(currentState, eventId);
      currentEventId = eventId;
      await currentEventChanged(eventId);
    }
  }
}
