import 'dart:async';

import 'package:fpdart/fpdart.dart';
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

  static Resource<StreamController<T>> streamController<T>(
          StreamController<T> Function() makeController) =>
      make(() => Future.sync(() => makeController()),
          (controller) => controller.close());

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
    late T r;
    try {
      r = await f(a);
    } finally {
      await finalizer();
    }
    return r;
  }

  Future<A> get use_ async {
    final (a, finalizer) = await allocated();
    await finalizer();
    return a;
  }

  Future<(A, Future<void> Function())> allocated();

  Resource<O> evalMap<O>(Future<O> Function(A) f) =>
      flatMap((a) => EvalResource(aF: () => f(a)));

  Resource<A> evalTap(Future<void> Function(A) f) =>
      flatMap((a) => EvalResource(aF: () async {
            await f(a);
            return a;
          }));

  Resource<(A, A2)> product<A2>(Resource<A2> rA2) => ParBindResources(
      sources: [this, rA2], fs: (vs) => pure((vs[0] as A, vs[1] as A2)));
}

class BindResource<S, A> extends Resource<A> {
  final Resource<S> source;
  final Resource<A> Function(S) fs;

  BindResource({required this.source, required this.fs});

  @override
  Future<(A, Future<void> Function())> allocated() async {
    final (sourceA, sourceFinalizer) = await source.allocated();
    final rA = fs(sourceA);
    late final A a;
    late final Future<void> Function() rAFinalizer;
    try {
      final r = await rA.allocated();
      a = r.$1;
      rAFinalizer = r.$2;
    } catch (e) {
      await sourceFinalizer();
      rethrow;
    }
    bool isFinalized = false;
    return (
      a,
      () async {
        if (!isFinalized) {
          isFinalized = true;
          await rAFinalizer();
          await sourceFinalizer();
        }
      }
    );
  }
}

class ParBindResources<A> extends Resource<A> {
  final List<Resource> sources;
  final Resource<A> Function(List<dynamic>) fs;

  ParBindResources({required this.sources, required this.fs});

  @override
  Future<(A, Future<void> Function())> allocated() async {
    final allocatedSourcesFutures = sources
        .map((s) => s
            .allocated()
            .then((r) => right<Object, (dynamic, Future<void> Function())>(r))
            .catchError((e) =>
                left<Object, (dynamic, Future<void> Function())>((e, s))))
        .toList();
    final allocatedSourcesEithers = await Future.wait(allocatedSourcesFutures);
    Object? error;
    for (final either in allocatedSourcesEithers) {
      if (either.isLeft()) error = either.getLeft().toNullable()!;
    }
    if (error != null) {
      for (final either in allocatedSourcesEithers) {
        if (either.isRight()) await either.getRight().toNullable()!.$2;
      }
      throw error;
    }
    final allocatedSources =
        allocatedSourcesEithers.map((e) => e.getRight().toNullable()!).toList();
    final rA = fs(allocatedSources.map((s) => s.$1).toList());
    late final A a;
    late final Future<void> Function() rAFinalizer;
    try {
      final r = await rA.allocated();
      a = r.$1;
      rAFinalizer = r.$2;
    } catch (e) {
      await Future.wait(allocatedSources.map((r) => r.$2()).toList());
      rethrow;
    }
    bool isFinalized = false;
    return (
      a,
      () async {
        if (!isFinalized) {
          isFinalized = true;
          await rAFinalizer();
          await Future.wait(allocatedSources.map((a) => a.$2()).toList());
        }
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
