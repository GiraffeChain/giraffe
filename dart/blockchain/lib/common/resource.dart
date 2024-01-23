import 'dart:async';

import 'package:logging/logging.dart';
import 'package:ribs_core/ribs_core.dart';

class ResourceUtils {
  static Resource<BackgroundHandler> backgroundStream(Stream s) =>
      Resource.pure(Completer())
          .flatMap((outcome) => forStreamSubscription(() => s.listen(
                    null,
                    onError: (Object e, StackTrace s) =>
                        outcome.completeError(e, s),
                    onDone: () => outcome.complete(),
                    cancelOnError: true,
                  )).map((s) {
                bool isCanceled = false;
                return BackgroundHandler(
                    done: outcome.future,
                    cancel: () async {
                      if (isCanceled) return;
                      isCanceled = true;
                      s.cancel();
                      if (!outcome.isCompleted) outcome.complete();
                    });
              }));

  static Resource<StreamSubscription<T>> forStreamSubscription<T>(
          StreamSubscription<T> Function() subscriptionF) =>
      Resource.make(
          IO.delay(() => subscriptionF()),
          (subscription) =>
              IO.fromFutureF(() => subscription.cancel()).voided());

  static Resource<StreamController<T>> streamController<T>(
          StreamController<T> Function() makeController) =>
      Resource.make(IO.delay(() => makeController()),
          (controller) => IO.fromFutureF(() => controller.close()).voided());
}

class BackgroundHandler {
  final Future<void> done;
  final Future Function() cancel;

  BackgroundHandler({required this.done, required this.cancel});
}

extension ResourceOps<A> on Resource<A> {
  Resource<A> tap(Function(A) f) => map((a) {
        f(a);
        return a;
      });

  Resource<A> tapLog(Logger log, String Function(A) messageF) => map((a) {
        log.info(messageF(a));
        return a;
      });

  Resource<A> flatTap<B>(Resource<B> Function(A) f) =>
      flatMap((a) => f(a).as(a));

  Resource<A> onFinalize(IO<Unit> Function(A) f) =>
      flatTap((a) => Resource.make(IO.unit, (_) => f(a)));

  Resource<A> tapLogFinalize(Logger log, String message) =>
      onFinalize((_) => IO.delay(() => log.info(message)).voided());

  Resource<B> evalFlatMap<B>(Future<Resource<B>> Function(A) f) =>
      evalMap((a) => IO.fromFutureF(() => f(a))).flatMap(identity);
}

/// {@macro io_tuple_ops}
extension Tuple6ResourceOps<A, B, C, D, E, F> on (
  Resource<A>,
  Resource<B>,
  Resource<C>,
  Resource<D>,
  Resource<E>,
  Resource<F>
) {
  /// {@macro io_mapN}
  Resource<G> mapN<G>(Function6<A, B, C, D, E, F, G> fn) =>
      tupled().map(fn.tupled);

  /// {@macro io_parMapN}
  Resource<G> parMapN<G>(Function6<A, B, C, D, E, F, G> fn) =>
      parTupled().map(fn.tupled);

  /// {@macro io_tupled}
  Resource<(A, B, C, D, E, F)> tupled() =>
      init().tupled().flatMap((x) => last.map((a) => x.append(a)));

  /// {@macro io_parTupled}
  Resource<(A, B, C, D, E, F)> parTupled() =>
      Resource.both(init().parTupled(), last).map((t) => t.$1.append(t.$2));
}

/// {@macro io_tuple_ops}
extension Tuple7ResourceOps<A, B, C, D, E, F, G> on (
  Resource<A>,
  Resource<B>,
  Resource<C>,
  Resource<D>,
  Resource<E>,
  Resource<F>,
  Resource<G>
) {
  /// {@macro io_mapN}
  Resource<H> mapN<H>(Function7<A, B, C, D, E, F, G, H> fn) =>
      tupled().map(fn.tupled);

  /// {@macro io_parMapN}
  Resource<H> parMapN<H>(Function7<A, B, C, D, E, F, G, H> fn) =>
      parTupled().map(fn.tupled);

  /// {@macro io_tupled}
  Resource<(A, B, C, D, E, F, G)> tupled() =>
      init().tupled().flatMap((x) => last.map((a) => x.append(a)));

  /// {@macro io_parTupled}
  Resource<(A, B, C, D, E, F, G)> parTupled() =>
      Resource.both(init().parTupled(), last).map((t) => t.$1.append(t.$2));
}

/// {@macro io_tuple_ops}
extension Tuple8ResourceOps<A, B, C, D, E, F, G, H> on (
  Resource<A>,
  Resource<B>,
  Resource<C>,
  Resource<D>,
  Resource<E>,
  Resource<F>,
  Resource<G>,
  Resource<H>
) {
  /// {@macro io_mapN}
  Resource<I> mapN<I>(Function8<A, B, C, D, E, F, G, H, I> fn) =>
      tupled().map(fn.tupled);

  /// {@macro io_parMapN}
  Resource<I> parMapN<I>(Function8<A, B, C, D, E, F, G, H, I> fn) =>
      parTupled().map(fn.tupled);

  /// {@macro io_tupled}
  Resource<(A, B, C, D, E, F, G, H)> tupled() =>
      init().tupled().flatMap((x) => last.map((a) => x.append(a)));

  /// {@macro io_parTupled}
  Resource<(A, B, C, D, E, F, G, H)> parTupled() =>
      Resource.both(init().parTupled(), last).map((t) => t.$1.append(t.$2));
}

/// {@macro io_tuple_ops}
extension Tuple9ResourceOps<A, B, C, D, E, F, G, H, I> on (
  Resource<A>,
  Resource<B>,
  Resource<C>,
  Resource<D>,
  Resource<E>,
  Resource<F>,
  Resource<G>,
  Resource<H>,
  Resource<I>
) {
  /// {@macro io_mapN}
  Resource<J> mapN<J>(Function9<A, B, C, D, E, F, G, H, I, J> fn) =>
      tupled().map(fn.tupled);

  /// {@macro io_parMapN}
  Resource<J> parMapN<J>(Function9<A, B, C, D, E, F, G, H, I, J> fn) =>
      parTupled().map(fn.tupled);

  /// {@macro io_tupled}
  Resource<(A, B, C, D, E, F, G, H, I)> tupled() =>
      init().tupled().flatMap((x) => last.map((a) => x.append(a)));

  /// {@macro io_parTupled}
  Resource<(A, B, C, D, E, F, G, H, I)> parTupled() =>
      Resource.both(init().parTupled(), last).map((t) => t.$1.append(t.$2));
}

/// {@macro io_tuple_ops}
extension Tuple10ResourceOps<A, B, C, D, E, F, G, H, I, J> on (
  Resource<A>,
  Resource<B>,
  Resource<C>,
  Resource<D>,
  Resource<E>,
  Resource<F>,
  Resource<G>,
  Resource<H>,
  Resource<I>,
  Resource<J>
) {
  /// {@macro io_mapN}
  Resource<K> mapN<K>(Function10<A, B, C, D, E, F, G, H, I, J, K> fn) =>
      tupled().map(fn.tupled);

  /// {@macro io_parMapN}
  Resource<K> parMapN<K>(Function10<A, B, C, D, E, F, G, H, I, J, K> fn) =>
      parTupled().map(fn.tupled);

  /// {@macro io_tupled}
  Resource<(A, B, C, D, E, F, G, H, I, J)> tupled() =>
      init().tupled().flatMap((x) => last.map((a) => x.append(a)));

  /// {@macro io_parTupled}
  Resource<(A, B, C, D, E, F, G, H, I, J)> parTupled() =>
      Resource.both(init().parTupled(), last).map((t) => t.$1.append(t.$2));
}

/// {@macro io_tuple_ops}
extension Tuple11ResourceOps<A, B, C, D, E, F, G, H, I, J, K> on (
  Resource<A>,
  Resource<B>,
  Resource<C>,
  Resource<D>,
  Resource<E>,
  Resource<F>,
  Resource<G>,
  Resource<H>,
  Resource<I>,
  Resource<J>,
  Resource<K>
) {
  /// {@macro io_mapN}
  Resource<L> mapN<L>(Function11<A, B, C, D, E, F, G, H, I, J, K, L> fn) =>
      tupled().map(fn.tupled);

  /// {@macro io_parMapN}
  Resource<L> parMapN<L>(Function11<A, B, C, D, E, F, G, H, I, J, K, L> fn) =>
      parTupled().map(fn.tupled);

  /// {@macro io_tupled}
  Resource<(A, B, C, D, E, F, G, H, I, J, K)> tupled() =>
      init().tupled().flatMap((x) => last.map((a) => x.append(a)));

  /// {@macro io_parTupled}
  Resource<(A, B, C, D, E, F, G, H, I, J, K)> parTupled() =>
      Resource.both(init().parTupled(), last).map((t) => t.$1.append(t.$2));
}

/// {@macro io_tuple_ops}
extension Tuple12ResourceOps<A, B, C, D, E, F, G, H, I, J, K, L> on (
  Resource<A>,
  Resource<B>,
  Resource<C>,
  Resource<D>,
  Resource<E>,
  Resource<F>,
  Resource<G>,
  Resource<H>,
  Resource<I>,
  Resource<J>,
  Resource<K>,
  Resource<L>
) {
  /// {@macro io_mapN}
  Resource<M> mapN<M>(Function12<A, B, C, D, E, F, G, H, I, J, K, L, M> fn) =>
      tupled().map(fn.tupled);

  /// {@macro io_parMapN}
  Resource<M> parMapN<M>(
          Function12<A, B, C, D, E, F, G, H, I, J, K, L, M> fn) =>
      parTupled().map(fn.tupled);

  /// {@macro io_tupled}
  Resource<(A, B, C, D, E, F, G, H, I, J, K, L)> tupled() =>
      init().tupled().flatMap((x) => last.map((a) => x.append(a)));

  /// {@macro io_parTupled}
  Resource<(A, B, C, D, E, F, G, H, I, J, K, L)> parTupled() =>
      Resource.both(init().parTupled(), last).map((t) => t.$1.append(t.$2));
}

/// {@macro io_tuple_ops}
extension Tuple13ResourceOps<A, B, C, D, E, F, G, H, I, J, K, L, M> on (
  Resource<A>,
  Resource<B>,
  Resource<C>,
  Resource<D>,
  Resource<E>,
  Resource<F>,
  Resource<G>,
  Resource<H>,
  Resource<I>,
  Resource<J>,
  Resource<K>,
  Resource<L>,
  Resource<M>
) {
  /// {@macro io_mapN}
  Resource<N> mapN<N>(
          Function13<A, B, C, D, E, F, G, H, I, J, K, L, M, N> fn) =>
      tupled().map(fn.tupled);

  /// {@macro io_parMapN}
  Resource<N> parMapN<N>(
          Function13<A, B, C, D, E, F, G, H, I, J, K, L, M, N> fn) =>
      parTupled().map(fn.tupled);

  /// {@macro io_tupled}
  Resource<(A, B, C, D, E, F, G, H, I, J, K, L, M)> tupled() =>
      init().tupled().flatMap((x) => last.map((a) => x.append(a)));

  /// {@macro io_parTupled}
  Resource<(A, B, C, D, E, F, G, H, I, J, K, L, M)> parTupled() =>
      Resource.both(init().parTupled(), last).map((t) => t.$1.append(t.$2));
}

/// {@macro io_tuple_ops}
extension Tuple14ResourceOps<A, B, C, D, E, F, G, H, I, J, K, L, M, N> on (
  Resource<A>,
  Resource<B>,
  Resource<C>,
  Resource<D>,
  Resource<E>,
  Resource<F>,
  Resource<G>,
  Resource<H>,
  Resource<I>,
  Resource<J>,
  Resource<K>,
  Resource<L>,
  Resource<M>,
  Resource<N>
) {
  /// {@macro io_mapN}
  Resource<O> mapN<O>(
          Function14<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O> fn) =>
      tupled().map(fn.tupled);

  /// {@macro io_parMapN}
  Resource<O> parMapN<O>(
          Function14<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O> fn) =>
      parTupled().map(fn.tupled);

  /// {@macro io_tupled}
  Resource<(A, B, C, D, E, F, G, H, I, J, K, L, M, N)> tupled() =>
      init().tupled().flatMap((x) => last.map((a) => x.append(a)));

  /// {@macro io_parTupled}
  Resource<(A, B, C, D, E, F, G, H, I, J, K, L, M, N)> parTupled() =>
      Resource.both(init().parTupled(), last).map((t) => t.$1.append(t.$2));
}

/// {@macro io_tuple_ops}
extension Tuple15ResourceOps<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O> on (
  Resource<A>,
  Resource<B>,
  Resource<C>,
  Resource<D>,
  Resource<E>,
  Resource<F>,
  Resource<G>,
  Resource<H>,
  Resource<I>,
  Resource<J>,
  Resource<K>,
  Resource<L>,
  Resource<M>,
  Resource<N>,
  Resource<O>
) {
  /// {@macro io_mapN}
  Resource<P> mapN<P>(
          Function15<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P> fn) =>
      tupled().map(fn.tupled);

  /// {@macro io_parMapN}
  Resource<P> parMapN<P>(
          Function15<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P> fn) =>
      parTupled().map(fn.tupled);

  /// {@macro io_tupled}
  Resource<(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O)> tupled() =>
      init().tupled().flatMap((x) => last.map((a) => x.append(a)));

  /// {@macro io_parTupled}
  Resource<(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O)> parTupled() =>
      Resource.both(init().parTupled(), last).map((t) => t.$1.append(t.$2));
}

/// {@macro io_tuple_ops}
extension Tuple16ResourceOps<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P>
    on (
  Resource<A>,
  Resource<B>,
  Resource<C>,
  Resource<D>,
  Resource<E>,
  Resource<F>,
  Resource<G>,
  Resource<H>,
  Resource<I>,
  Resource<J>,
  Resource<K>,
  Resource<L>,
  Resource<M>,
  Resource<N>,
  Resource<O>,
  Resource<P>
) {
  /// {@macro io_mapN}
  Resource<Q> mapN<Q>(
          Function16<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q> fn) =>
      tupled().map(fn.tupled);

  /// {@macro io_parMapN}
  Resource<Q> parMapN<Q>(
          Function16<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q> fn) =>
      parTupled().map(fn.tupled);

  /// {@macro io_tupled}
  Resource<(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P)> tupled() =>
      init().tupled().flatMap((x) => last.map((a) => x.append(a)));

  /// {@macro io_parTupled}
  Resource<(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P)> parTupled() =>
      Resource.both(init().parTupled(), last).map((t) => t.$1.append(t.$2));
}

/// {@macro io_tuple_ops}
extension Tuple17ResourceOps<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q>
    on (
  Resource<A>,
  Resource<B>,
  Resource<C>,
  Resource<D>,
  Resource<E>,
  Resource<F>,
  Resource<G>,
  Resource<H>,
  Resource<I>,
  Resource<J>,
  Resource<K>,
  Resource<L>,
  Resource<M>,
  Resource<N>,
  Resource<O>,
  Resource<P>,
  Resource<Q>
) {
  /// {@macro io_mapN}
  Resource<R> mapN<R>(
          Function17<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R>
              fn) =>
      tupled().map(fn.tupled);

  /// {@macro io_parMapN}
  Resource<R> parMapN<R>(
          Function17<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R>
              fn) =>
      parTupled().map(fn.tupled);

  /// {@macro io_tupled}
  Resource<(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q)> tupled() =>
      init().tupled().flatMap((x) => last.map((a) => x.append(a)));

  /// {@macro io_parTupled}
  Resource<(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q)> parTupled() =>
      Resource.both(init().parTupled(), last).map((t) => t.$1.append(t.$2));
}

/// {@macro io_tuple_ops}
extension Tuple18ResourceOps<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q,
    R> on (
  Resource<A>,
  Resource<B>,
  Resource<C>,
  Resource<D>,
  Resource<E>,
  Resource<F>,
  Resource<G>,
  Resource<H>,
  Resource<I>,
  Resource<J>,
  Resource<K>,
  Resource<L>,
  Resource<M>,
  Resource<N>,
  Resource<O>,
  Resource<P>,
  Resource<Q>,
  Resource<R>
) {
  /// {@macro io_mapN}
  Resource<S> mapN<S>(
          Function18<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S>
              fn) =>
      tupled().map(fn.tupled);

  /// {@macro io_parMapN}
  Resource<S> parMapN<S>(
          Function18<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S>
              fn) =>
      parTupled().map(fn.tupled);

  /// {@macro io_tupled}
  Resource<(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R)> tupled() =>
      init().tupled().flatMap((x) => last.map((a) => x.append(a)));

  /// {@macro io_parTupled}
  Resource<(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R)>
      parTupled() =>
          Resource.both(init().parTupled(), last).map((t) => t.$1.append(t.$2));
}

/// {@macro io_tuple_ops}
extension Tuple19ResourceOps<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q,
    R, S> on (
  Resource<A>,
  Resource<B>,
  Resource<C>,
  Resource<D>,
  Resource<E>,
  Resource<F>,
  Resource<G>,
  Resource<H>,
  Resource<I>,
  Resource<J>,
  Resource<K>,
  Resource<L>,
  Resource<M>,
  Resource<N>,
  Resource<O>,
  Resource<P>,
  Resource<Q>,
  Resource<R>,
  Resource<S>
) {
  /// {@macro io_mapN}
  Resource<T> mapN<T>(
          Function19<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T>
              fn) =>
      tupled().map(fn.tupled);

  /// {@macro io_parMapN}
  Resource<T> parMapN<T>(
          Function19<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T>
              fn) =>
      parTupled().map(fn.tupled);

  /// {@macro io_tupled}
  Resource<(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S)>
      tupled() => init().tupled().flatMap((x) => last.map((a) => x.append(a)));

  /// {@macro io_parTupled}
  Resource<(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S)>
      parTupled() =>
          Resource.both(init().parTupled(), last).map((t) => t.$1.append(t.$2));
}

/// {@macro io_tuple_ops}
extension Tuple20ResourceOps<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q,
    R, S, T> on (
  Resource<A>,
  Resource<B>,
  Resource<C>,
  Resource<D>,
  Resource<E>,
  Resource<F>,
  Resource<G>,
  Resource<H>,
  Resource<I>,
  Resource<J>,
  Resource<K>,
  Resource<L>,
  Resource<M>,
  Resource<N>,
  Resource<O>,
  Resource<P>,
  Resource<Q>,
  Resource<R>,
  Resource<S>,
  Resource<T>
) {
  /// {@macro io_mapN}
  Resource<U> mapN<U>(
          Function20<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T,
                  U>
              fn) =>
      tupled().map(fn.tupled);

  /// {@macro io_parMapN}
  Resource<U> parMapN<U>(
          Function20<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T,
                  U>
              fn) =>
      parTupled().map(fn.tupled);

  /// {@macro io_tupled}
  Resource<(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T)>
      tupled() => init().tupled().flatMap((x) => last.map((a) => x.append(a)));

  /// {@macro io_parTupled}
  Resource<(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T)>
      parTupled() =>
          Resource.both(init().parTupled(), last).map((t) => t.$1.append(t.$2));
}

/// {@macro io_tuple_ops}
extension Tuple21ResourceOps<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q,
    R, S, T, U> on (
  Resource<A>,
  Resource<B>,
  Resource<C>,
  Resource<D>,
  Resource<E>,
  Resource<F>,
  Resource<G>,
  Resource<H>,
  Resource<I>,
  Resource<J>,
  Resource<K>,
  Resource<L>,
  Resource<M>,
  Resource<N>,
  Resource<O>,
  Resource<P>,
  Resource<Q>,
  Resource<R>,
  Resource<S>,
  Resource<T>,
  Resource<U>
) {
  /// {@macro io_mapN}
  Resource<V> mapN<V>(
          Function21<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T,
                  U, V>
              fn) =>
      tupled().map(fn.tupled);

  /// {@macro io_parMapN}
  Resource<V> parMapN<V>(
          Function21<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T,
                  U, V>
              fn) =>
      parTupled().map(fn.tupled);

  /// {@macro io_tupled}
  Resource<(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U)>
      tupled() => init().tupled().flatMap((x) => last.map((a) => x.append(a)));

  /// {@macro io_parTupled}
  Resource<(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U)>
      parTupled() =>
          Resource.both(init().parTupled(), last).map((t) => t.$1.append(t.$2));
}

/// {@macro io_tuple_ops}
extension Tuple22ResourceOps<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q,
    R, S, T, U, V> on (
  Resource<A>,
  Resource<B>,
  Resource<C>,
  Resource<D>,
  Resource<E>,
  Resource<F>,
  Resource<G>,
  Resource<H>,
  Resource<I>,
  Resource<J>,
  Resource<K>,
  Resource<L>,
  Resource<M>,
  Resource<N>,
  Resource<O>,
  Resource<P>,
  Resource<Q>,
  Resource<R>,
  Resource<S>,
  Resource<T>,
  Resource<U>,
  Resource<V>
) {
  /// {@macro io_mapN}
  Resource<W> mapN<W>(
          Function22<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T,
                  U, V, W>
              fn) =>
      tupled().map(fn.tupled);

  /// {@macro io_parMapN}
  Resource<W> parMapN<W>(
          Function22<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T,
                  U, V, W>
              fn) =>
      parTupled().map(fn.tupled);

  /// {@macro io_tupled}
  Resource<(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V)>
      tupled() => init().tupled().flatMap((x) => last.map((a) => x.append(a)));

  /// {@macro io_parTupled}
  Resource<(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V)>
      parTupled() => Resource.both(init().parTupled(), last)
          .map((t) => t((a, b) => a.append(b)));
}
