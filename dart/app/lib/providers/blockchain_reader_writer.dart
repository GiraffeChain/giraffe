import 'package:blockchain_app/providers/rpc_channel.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_protobuf/services/node_rpc.pbgrpc.dart';
import 'package:blockchain_protobuf/services/staker_support_rpc.pbgrpc.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'blockchain_reader_writer.g.dart';
part 'blockchain_reader_writer.freezed.dart';

@riverpod
class PodBlockchainReaderWriter extends _$PodBlockchainReaderWriter {
  @override
  BlockchainReaderWriter build() {
    final channel = ref.watch(podRpcChannelProvider);
    final nodeClient = NodeRpcClientWithRetry(channel,
        delegate: NodeRpcClient(channel), maxTries: 10);
    final stakerSupportClient = StakerSupportRpcClientWithRetry(channel,
        delegate: StakerSupportRpcClient(channel), maxTries: 10);
    final view = BlockchainViewFromRpc(nodeClient: nodeClient);
    final writer = BlockchainWriter(
        submitTransaction: (tx) => nodeClient
            .broadcastTransaction(BroadcastTransactionReq(transaction: tx)),
        stakerClient: stakerSupportClient);
    return BlockchainReaderWriter(view: view, writer: writer);
  }
}

@freezed
class BlockchainReaderWriter with _$BlockchainReaderWriter {
  const factory BlockchainReaderWriter({
    required BlockchainView view,
    required BlockchainWriter writer,
  }) = _BlockchainReaderWriter;
}

class BlockchainWriter {
  final Future<void> Function(Transaction) submitTransaction;
  final StakerSupportRpcClient stakerClient;

  BlockchainWriter(
      {required this.submitTransaction, required this.stakerClient});
}
