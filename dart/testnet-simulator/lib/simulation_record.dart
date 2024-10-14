import 'package:fixnum/fixnum.dart';

class SimulationRecord {
  final String dropletId;
  final Int64 recordTimestamp;
  final String blockId;
  final Int64 timestamp;
  final Int64 height;
  final Int64 slot;
  final String staker;

  SimulationRecord({
    required this.dropletId,
    required this.recordTimestamp,
    required this.blockId,
    required this.timestamp,
    required this.height,
    required this.slot,
    required this.staker,
  });

  Map<String, dynamic> toJson() => {
        "dropletId": dropletId,
        "recordTimestamp": recordTimestamp.toInt(),
        "blockId": blockId,
        "timestamp": timestamp.toInt(),
        "height": height.toInt(),
        "slot": slot.toInt(),
        "staker": staker,
      };
}
