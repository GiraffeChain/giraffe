import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:integral_isolates/integral_isolates.dart';
import 'package:ribs_core/ribs_core.dart';
import 'package:ribs_effect/ribs_effect.dart';

class IsolatePool {
  final int maxIsolates;
  final List<StatefulIsolate> instances = [];

  IsolatePool(this.maxIsolates);

  static Resource<IsolatePool> make({int? maxIsolates}) => Resource.make(
      IO.delay(() => IsolatePool(maxIsolates ?? Platform.numberOfProcessors)),
      (pool) => IList.fromDart(pool.instances)
          .parTraverseIO((a) => IO.fromFutureF(() => a.dispose()))
          .voided());

  StatefulIsolate getIsolate() {
    if (instances.length < maxIsolates) {
      final instance = StatefulIsolate();
      instances.add(instance);
      return instance;
    } else {
      return instances[Random().nextInt(maxIsolates)];
    }
  }

  Future<R> isolate<Q, R>(FutureOr<R> Function(Q message) callback, Q message,
          {String? debugLabel}) =>
      getIsolate().isolate(callback, message, debugLabel: debugLabel);
}
