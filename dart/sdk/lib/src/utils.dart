import 'dart:async';
import 'dart:typed_data';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:logging/logging.dart';
import 'package:ribs_core/ribs_core.dart';
import 'package:ribs_effect/ribs_effect.dart';

final _bigIntByteMask = new BigInt.from(0xff);

extension BigIntOps on BigInt {
  // Source: https://github.com/PointyCastle/pointycastle/blob/master/lib/src/utils.dart
  Uint8List get bytesBigEndian2 {
    final byteLen = bitLength ~/ 8 + 1;
    final byteArray = Uint8List(byteLen);
    for (int i = byteLen - 1, bytesCopied = 4, nextInt = 0, intIndex = 0;
        i >= 0;
        i--) {
      if (bytesCopied == 4) {
        nextInt = getInt(intIndex++);
        bytesCopied = 1;
      } else {
        nextInt >>>= 8;
        bytesCopied++;
      }
      byteArray[i] = nextInt;
    }
    return byteArray;
  }

  int getInt(int n) {
    throw UnimplementedError();
  }

  int get signum {
    if (this > BigInt.one)
      return 1;
    else if (this == BigInt.zero)
      return 0;
    else
      return -1;
  }

  int get signInt => (signum < 0) ? -1 : 0;

  Uint8List get bytesBigEndian {
    BigInt number = this;
    // Not handling negative numbers. Decide how you want to do that.
    int size = (bitLength + 7) >> 3;
    var result = new Uint8List(size);
    for (int i = 0; i < size; i++) {
      result[size - i - 1] = (number & _bigIntByteMask).toInt();
      number = number >> 8;
    }
    return result;
  }

  // Source: https://github.com/dart-lang/sdk/issues/32803#issuecomment-1228291047
  Uint8List get bytesLittleEndian {
    final data = ByteData(bitLength ~/ 8 + 1);
    var _bigInt = this;

    for (var i = data.lengthInBytes - 1; i >= 0; i--) {
      data.setUint8(i, _bigInt.toUnsigned(8).toInt());
      _bigInt = _bigInt >> 8;
    }

    return Uint8List.view(data.buffer);
  }
}

extension Int32Ops on Int32 {
  BigInt get toBigInt => BigInt.from(this.toInt());
  List<int> toBytesBigEndian() {
    Int32 value = this;
    final res = Uint8List(4);
    for (int i = 3; i >= 0; i--) {
      res[i] = (value & 0xff).toInt();
      value >>= 8;
    }
    return res;
  }
}

extension Int64Ops on Int64 {
  BigInt get toBigInt => BigInt.parse(toString());
  List<int> toBytesBigEndian() {
    Int64 value = this;
    final res = Uint8List(8);
    for (int i = 7; i >= 0; i--) {
      res[i] = (value & 0xff).toInt();
      value >>= 8;
    }
    return res;
  }
}

extension ListIntOps on List<int> {
  BigInt get toBigInt {
    final data = Int8List.fromList(this).buffer.asByteData();
    BigInt _bigInt = BigInt.zero;

    for (var i = 0; i < data.lengthInBytes; i++) {
      _bigInt = (_bigInt << 8) | BigInt.from(data.getUint8(i));
    }
    return _bigInt;
  }
}

extension TransactionOps on Transaction {
  Int64 get inputSum =>
      inputs.fold(Int64.ZERO, (a, input) => a + input.value.quantity);
  Int64 get outputSum =>
      outputs.fold(Int64.ZERO, (a, input) => a + input.value.quantity);
  Int64 get reward => inputSum - outputSum;
}

extension LogOps on Logger {
  T timedInfo<T>(T Function() f, {String Function(Duration)? messageF}) {
    final start = DateTime.now();
    final r = f();
    final duration = DateTime.now().difference(start);
    final message = (messageF != null)
        ? messageF(duration)
        : "Operation took ${duration.inMilliseconds}";
    info(message);
    return r;
  }

  Future<T> timedInfoAsync<T>(Future<T> Function() f,
      {String Function(Duration)? messageF}) async {
    final start = DateTime.now();
    final r = await f();
    final duration = DateTime.now().difference(start);
    final message = (messageF != null)
        ? messageF(duration)
        : "Operation took ${duration.inMilliseconds}";
    info(message);
    return r;
  }
}

extension FutureOps<T> on Future<T> {
  Future<T> get voidError => onError((_, __) => (null as T));

  Future<T> logError(Logger log, String message) =>
      onError<Object>((e, stackTrace) async {
        log.warning(message, e, stackTrace);
        throw e;
      });

  Future<Either<T, O>> race<O>(Future<O> f) => Future.any([
        then((res) => Either.left<T, O>(res)),
        f.then((res) => Either.right<T, O>(res))
      ]);
}

initRootLogger() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    final _errorSuffix = (record.error != null) ? ": ${record.error}" : "";
    final _stackTraceSuffix =
        (record.stackTrace != null) ? "\n${record.stackTrace}" : "";
    print(
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}${_errorSuffix}${_stackTraceSuffix}');
  });
}

final unit = Unit();

StreamTransformer<In, Out> AbandoningTransformer<In, Out>(
        IO<Out> Function(In) f) =>
    StreamTransformer((Stream<In> stream, cancelOnError) {
      final controller = StreamController<Out>(sync: true);
      controller.onListen = () {
        Future<Unit> Function()? cancel;
        final subscription = stream.listen((data) {
          final baseIo = f(data).flatTap((out) => IO.delay(() {
                cancel = null;
                if (out != null) controller.add(out);
              }));
          final io = (cancel != null)
              ? IO
                  .fromFutureF(() => cancel!())
                  .flatTap((_) => IO.delay(() => cancel = null))
                  .flatMap((_) => baseIo)
              : baseIo;
          final (future, c) = io.unsafeRunFutureCancelable();
          cancel = c;
          future.catchError((e, s) {
            controller.addError(e!, s);
            throw e;
          });
        },
            onError: controller.addError,
            onDone: controller.close,
            cancelOnError: cancelOnError);
        controller
          ..onPause = subscription.pause
          ..onResume = subscription.resume
          ..onCancel = () async {
            if (cancel != null) await cancel!();
            await subscription.cancel;
          };
      };
      return controller.stream.listen(null);
    });
