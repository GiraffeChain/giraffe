import 'dart:async';
import 'dart:math';

import 'package:blockchain/common/resource.dart';
import 'package:integral_isolates/integral_isolates.dart';

class IsolatePool {
  final int maxIsolates;
  final List<StatefulIsolate> instances = [];

  IsolatePool(this.maxIsolates);

  static Resource<IsolatePool> make(int maxIsolates) => Resource.make(
      () => Future.sync(() => IsolatePool(maxIsolates)),
      (pool) => Future.wait(pool.instances.map((i) => i.dispose()).toList()));

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
