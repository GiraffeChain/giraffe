import 'dart:async';
import 'dart:typed_data';

import 'package:blockchain/crypto/ed25519.dart';
import 'package:blockchain/crypto/ed25519vrf.dart';
import 'package:blockchain/crypto/impl/kes_product.dart';
import 'package:collection/collection.dart';
import 'package:hashlib/hashlib.dart';

extension IterableEqOps<T> on Iterable<T> {
  bool sameElements(Iterable<T> other) =>
      const IterableEquality().equals(this, other);
}

extension Uint8ListOps on Uint8List {
  Int8List get int8List => Int8List.fromList(this);
}

extension ListIntOps on List<int> {
  Uint8List get hash256 => blake2b256.convert(this).bytes;

  Uint8List get hash512 => blake2b512.convert(this).bytes;
}

// Alias's Flutter's "compute()" function signature
typedef DComputeCallback<Q, R> = FutureOr<R> Function(Q message);

typedef DComputeImpl = Future<R> Function<Q, R>(
    DComputeCallback<Q, R> callback, Q message,
    {String? debugLabel});

Future<R> LocalCompute<Q, R>(DComputeCallback<Q, R> callback, Q message,
        {String? debugLabel}) async =>
    callback(message);

void setComputeFunction(DComputeImpl isolate) {
  ed25519 = Ed25519Isolated(isolate);
  ed25519Vrf = Ed25519VRFIsolated(isolate);
  kesProduct = KesProudctIsolated(isolate);
}
