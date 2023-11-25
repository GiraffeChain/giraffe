import 'dart:async';
import 'dart:math';

import 'package:integral_isolates/integral_isolates.dart';

class IsolatePool {
  final int maxIsolates;
  final List<StatefulIsolate> _instances = [];

  IsolatePool(this.maxIsolates);

  StatefulIsolate getIsolate() {
    if (_instances.length < maxIsolates) {
      final instance = StatefulIsolate();
      _instances.add(instance);
      return instance;
    } else {
      return _instances[Random().nextInt(maxIsolates)];
    }
  }

  Future<R> isolate<Q, R>(FutureOr<R> Function(Q message) callback, Q message,
          {String? debugLabel}) =>
      getIsolate().isolate(callback, message, debugLabel: debugLabel);
}
