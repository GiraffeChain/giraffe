import 'package:blockchain/common/clock.dart';
import 'package:blockchain/consensus/consensus_validation_state.dart';
import 'package:blockchain/consensus/eta_calculation.dart';
import 'package:blockchain/consensus/leader_election_validation.dart';
import 'package:blockchain/data_stores.dart';
import 'package:blockchain/common/parent_child_tree.dart';
import 'package:blockchain/consensus/block_header_to_body_validation.dart';
import 'package:blockchain/consensus/block_header_validation.dart';
import 'package:blockchain/ledger/body_authorization_validation.dart';
import 'package:blockchain/ledger/body_semantic_validation.dart';
import 'package:blockchain/ledger/body_syntax_validation.dart';
import 'package:blockchain/ledger/box_state.dart';
import 'package:blockchain/ledger/transaction_authorization_interpreter.dart';
import 'package:blockchain/ledger/transaction_semantic_validation.dart';
import 'package:blockchain/ledger/transaction_syntax_interpreter.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

class Validators {
  final BlockHeaderValidation header;
  final BlockHeaderToBodyValidationAlgebra headerToBody;
  final TransactionSyntaxVerifier transactionSyntax;
  final BodySyntaxValidationAlgebra bodySyntax;
  final BodySemanticValidationAlgebra bodySemantic;
  final BodyAuthorizationValidationAlgebra bodyAuthorization;
  final BoxStateAlgebra boxState;

  Validators(
    this.header,
    this.headerToBody,
    this.transactionSyntax,
    this.bodySyntax,
    this.bodySemantic,
    this.bodyAuthorization,
    this.boxState,
  );

  static Future<Validators> make(
    DataStores dataStores,
    BlockId genesisBlockId,
    CurrentEventIdGetterSetters currentEventIdGetterSetters,
    ParentChildTree<BlockId> parentChildTree,
    EtaCalculationAlgebra etaCalculation,
    ConsensusValidationStateAlgebra consensusValidationState,
    LeaderElectionValidationAlgebra leaderElectionValidation,
    ClockAlgebra clock,
  ) async {
    final headerValidation = BlockHeaderValidation(
        genesisBlockId,
        etaCalculation,
        consensusValidationState,
        leaderElectionValidation,
        clock,
        dataStores.headers.getOrRaise);

    final headerToBodyValidation = BlockHeaderToBodyValidation();

    final boxState = BoxState.make(
      dataStores.spendableBoxIds,
      await currentEventIdGetterSetters.boxState.get(),
      dataStores.bodies.getOrRaise,
      dataStores.transactions.getOrRaise,
      parentChildTree,
      currentEventIdGetterSetters.boxState.set,
    );

    final transactionSyntaxValidation = TransactionSyntaxInterpreter();
    final transactionSemanticValidation = TransactionSemanticValidation(
        dataStores.transactions.getOrRaise, boxState);
    final transactionAuthorizationValidation =
        TransactionAuthorizationInterpreter();
    final bodySyntaxValidation = BodySyntaxValidation(
        dataStores.transactions.getOrRaise, transactionSyntaxValidation);
    final bodySemanticValidation = BodySemanticValidation(
        dataStores.transactions.getOrRaise, transactionSemanticValidation);
    final bodyAuthorizationValidation = BodyAuthorizationValidation(
        dataStores.transactions.getOrRaise, transactionAuthorizationValidation);

    return Validators(
      headerValidation,
      headerToBodyValidation,
      transactionSyntaxValidation,
      bodySyntaxValidation,
      bodySemanticValidation,
      bodyAuthorizationValidation,
      boxState,
    );
  }
}
