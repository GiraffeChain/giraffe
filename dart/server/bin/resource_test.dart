import 'package:blockchain/common/resource.dart';
import 'package:blockchain/common/utils.dart';
import 'package:blockchain/network/merge_stream_eager_complete.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

Future<void> main() async {
  initRootLogger();
  final log = Logger("Test");
  await Resource.make(() async => 0, (_) async => log.info("0"))
      .tapLog(log, (_) => "Starting")
      .tapLogFinalize(log, "Stopping")
      .use((x) async => log.info(x + 1));

  await Resource.backgroundStream(MergeStreamEagerComplete([
    Stream.periodic(Duration(seconds: 1), (a) => a * 2).map((d) {
      print(d);
    }).take(5),
    Stream.periodic(Duration(seconds: 1), (a) => a * 2 + 1).map((d) {
      print(d);
    })
  ]))
      .tapLog(log, (_) => "Starting")
      .tapLogFinalize(log, "Stopping")
      .use((handler) async {
    await handler.done;
  });
}
