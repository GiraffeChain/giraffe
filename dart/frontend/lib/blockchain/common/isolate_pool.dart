import 'dart:async';
import 'dart:math';

import 'package:integral_isolates/integral_isolates.dart';

class IsolatePool {
  final int maxIsolates;
  final List<StatefulIsolate> instances = [];

  IsolatePool(this.maxIsolates);

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
      getIsolate().compute(callback, message, debugLabel: debugLabel);

  void dispose() {
    for (final instance in instances) {
      instance.dispose();
    }
  }
}
