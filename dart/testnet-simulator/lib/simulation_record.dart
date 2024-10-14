import 'package:fixnum/fixnum.dart';
import 'package:giraffe_protocol/protocol.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:giraffe_testnet_simulator/droplets.dart';

class SimulationRecord {
  final String dropletId;
  final Int64 recordTimestamp;
  final String blockId;
  final Int64 timestamp;
  final Int64 height;
  final Int64 slot;
  final int txCount;
  final String staker;

  SimulationRecord({
    required this.dropletId,
    required this.recordTimestamp,
    required this.blockId,
    required this.timestamp,
    required this.height,
    required this.slot,
    required this.txCount,
    required this.staker,
  });

  factory SimulationRecord.fromBlock(RelayDroplet relay, Block block) =>
      SimulationRecord(
        dropletId: relay.id,
        recordTimestamp: Int64(DateTime.now().millisecondsSinceEpoch),
        blockId: block.header.id.show,
        timestamp: block.header.timestamp,
        height: block.header.height,
        slot: block.header.slot,
        staker: block.header.account.show,
        txCount: block.body.transactionIds.length,
      );

  Map<String, dynamic> toJson() => {
        "dropletId": dropletId,
        "recordTimestamp": recordTimestamp.toInt(),
        "blockId": blockId,
        "timestamp": timestamp.toInt(),
        "height": height.toInt(),
        "slot": slot.toInt(),
        "txCount": txCount,
        "staker": staker,
      };
}
