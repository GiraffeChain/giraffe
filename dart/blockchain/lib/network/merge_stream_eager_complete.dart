import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/src/utils/subscription.dart';

class MergeStreamEagerComplete<T> extends StreamView<T> {
  /// Constructs a [Stream] which flattens all events in [streams] and emits
  /// them in a single sequence.  If any stream completes, the other streams will be canceled.
  MergeStreamEagerComplete(Iterable<Stream<T>> streams)
      : super(_buildController(streams).stream);

  static final log = Logger("MergeStreamEagerComplete");

  static StreamController<T> _buildController<T>(Iterable<Stream<T>> streams) {
    final controller = StreamController<T>(sync: true);
    late List<StreamSubscription<T>> subscriptions;

    bool done = false;

    controller.onListen = () {
      void onDone(int index) {
        if (!done) {
          done = true;
          for (int i = 0; i < subscriptions.length; i++) {
            if (i != index) subscriptions[i].cancel();
          }
          controller.close();
        }
      }

      subscriptions = streams
          .mapWithIndex((s, index) => s.listen(
                (v) {
                  if (!done) controller.add;
                },
                onError: (e, s) {
                  if (!done)
                    controller.addError(e, s);
                  else
                    log.warning("Received error after stream completion, e, s");
                },
                onDone: () => onDone(index),
              ))
          .toList(growable: false);

      if (subscriptions.isEmpty) {
        controller.close();
      }
    };
    controller.onPause = () => subscriptions.pauseAll();
    controller.onResume = () => subscriptions.resumeAll();
    controller.onCancel = () => subscriptions.cancelAll();

    return controller;
  }
}
