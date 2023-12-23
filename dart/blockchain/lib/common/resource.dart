import 'dart:async';

import 'package:logging/logging.dart';

abstract class Resource<A> {
  static Resource<A> pure<A>(A a) => PureResource(a: a);
  static Resource<A> make<A>(
      Future<A> Function() init, Future<void> Function(A) destroy) {
    return AllocateResource(resource: () async {
      final a = await init();
      return (a, () => destroy(a));
    });
  }

  static Resource<A> eval<A>(Future<A> Function() aF) => EvalResource(aF: aF);

  static Resource<void> onFinalize(Future<void> Function() f) =>
      make(() => Future.value(), (_) => f());

  static Resource<StreamSubscription<T>> forStreamSubscription<T>(
          StreamSubscription<T> Function() subscriptionF) =>
      make(() => Future.sync(() => subscriptionF()),
          (subscription) => subscription.cancel());

  Resource<void> get voidResult => map((_) => ());

  Resource<U> map<U>(U Function(A) f) => flatMap((t) => PureResource(a: f(t)));

  Resource<A> tap(void Function(A) f) => map((a) {
        f(a);
        return a;
      });

  Resource<U> flatMap<U>(Resource<U> Function(A) f) {
    return BindResource<A, U>(source: this, fs: f);
  }

  Resource<U> evalFlatMap<U>(Future<Resource<U>> Function(A) f) {
    return evalMap(f).flatMap((r) => r);
  }

  Resource<A> flatTap<U>(Resource Function(A) f) {
    return BindResource<A, A>(source: this, fs: (a) => f(a).map((_) => a));
  }

  Resource<A> tapLog(Logger log, String Function(A) messageF) => map((a) {
        log.info(messageF(a));
        return a;
      });

  Resource<A> tapLogFinalize(Logger log, String message) => flatTap(
      (a) => Resource.onFinalize(() => Future.sync(() => log.info(message))));

  Future<T> use<T>(Future<T> Function(A) f) async {
    final (a, finalizer) = await allocated();
    try {
      return await f(a);
    } finally {
      await finalizer;
    }
  }

  Future<(A, Future<void> Function())> allocated();

  Resource<O> evalMap<O>(Future<O> Function(A) f) =>
      flatMap((a) => EvalResource(aF: () => f(a)));

  Resource<A> evalTap(Future<void> Function(A) f) =>
      flatMap((a) => EvalResource(aF: () async {
            await f(a);
            return a;
          }));
}

class BindResource<S, A> extends Resource<A> {
  final Resource<S> source;
  final Resource<A> Function(S) fs;

  BindResource({required this.source, required this.fs});

  @override
  Future<(A, Future<void> Function())> allocated() async {
    final (sourceA, sourceFinalizer) = await source.allocated();
    final rA = fs(sourceA);
    final (a, rAFinalizer) = await rA.allocated();
    return (
      a,
      () async {
        await rAFinalizer();
        await sourceFinalizer();
      }
    );
  }
}

class AllocateResource<A> extends Resource<A> {
  final Future<(A, Future<void> Function())> Function() resource;

  AllocateResource({required this.resource});

  @override
  Future<(A, Future<void> Function())> allocated() => resource();
}

class PureResource<A> extends Resource<A> {
  final A a;

  PureResource({required this.a});

  @override
  Future<(A, Future<void> Function())> allocated() {
    return Future.value((a, () => Future.value()));
  }
}

class EvalResource<A> extends Resource<A> {
  final Future<A> Function() aF;

  EvalResource({required this.aF});

  @override
  Future<(A, Future<void> Function())> allocated() async {
    final a = await aF();
    return (a, () => Future.value());
  }
}
