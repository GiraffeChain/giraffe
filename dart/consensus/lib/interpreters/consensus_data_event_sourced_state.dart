import 'package:blockchain_common/algebras/event_sourced_state_algebra.dart';
import 'package:blockchain_common/algebras/parent_child_tree_algebra.dart';
import 'package:blockchain_common/algebras/store_algebra.dart';
import 'package:blockchain_common/interpreters/event_tree_state.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

class ConsensusData {
  final StoreAlgebra<StakingAddress, BigInt> operatorStakes;
  final StoreAlgebra<void, BigInt> totalActiveStake;
  final StoreAlgebra<StakingAddress, SignatureKesProduct> registrations;

  ConsensusData(this.operatorStakes, this.totalActiveStake, this.registrations);
}

EventSourcedStateAlgebra<ConsensusData, BlockId> consensusDataEventSourcedState(
    BlockId initialBlockId,
    ParentChildTreeAlgebra<BlockId> parentChildTree,
    Future<void> Function(BlockId) currentEventChanged,
    ConsensusData initialState,
    Future<BlockBody> Function(BlockId) fetchBlockBody,
    Future<Transaction> Function(TransactionId) fetchTransaction) {
  return EventTreeState(
      _applyBlock(fetchBlockBody, fetchTransaction),
      _unapplyBlock(fetchBlockBody, fetchTransaction),
      parentChildTree,
      initialState,
      initialBlockId,
      currentEventChanged);
}

Future<ConsensusData> Function(ConsensusData, BlockId) _applyBlock(
    Future<BlockBody> Function(BlockId) fetchBlockBody,
    Future<Transaction> Function(TransactionId) fetchTransaction) {
  Future<ConsensusData> apply(ConsensusData state, BlockId blockId) async {
    // TODO
    return state;
  }

  return apply;
}

Future<ConsensusData> Function(ConsensusData, BlockId) _unapplyBlock(
    Future<BlockBody> Function(BlockId) fetchBlockBody,
    Future<Transaction> Function(TransactionId) fetchTransaction) {
  Future<ConsensusData> f(ConsensusData state, BlockId blockId) async {
    // TODO
    return state;
  }

  return f;
}
