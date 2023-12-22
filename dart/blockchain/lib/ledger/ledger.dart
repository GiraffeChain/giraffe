import 'package:blockchain/common/parent_child_tree.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain/data_stores.dart';
import 'package:blockchain/ledger/body_authorization_validation.dart';
import 'package:blockchain/ledger/body_semantic_validation.dart';
import 'package:blockchain/ledger/body_syntax_validation.dart';
import 'package:blockchain/ledger/box_state.dart';
import 'package:blockchain/ledger/mempool.dart';
import 'package:blockchain/ledger/transaction_authorization_interpreter.dart';
import 'package:blockchain/ledger/transaction_semantic_validation.dart';
import 'package:blockchain/ledger/transaction_syntax_interpreter.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

class Ledger {
  final TransactionSyntaxVerifier transactionSyntaxValidation;
  final TransactionSemanticValidationAlgebra transactionSemanticValidation;
  final TransactionAuthorizationVerifier transactionAuthorizationValidation;
  final BodySyntaxValidationAlgebra bodySyntaxValidation;
  final BodySemanticValidationAlgebra bodySemanticValidation;
  final BodyAuthorizationValidationAlgebra bodyAuthorizationValidation;
  final BoxStateAlgebra boxState;
  final Mempool mempool;

  Ledger(
      {required this.transactionSyntaxValidation,
      required this.transactionSemanticValidation,
      required this.transactionAuthorizationValidation,
      required this.bodySyntaxValidation,
      required this.bodySemanticValidation,
      required this.bodyAuthorizationValidation,
      required this.boxState,
      required this.mempool});

  static Resource<Ledger> make(
    DataStores dataStores,
    CurrentEventIdGetterSetters currentEventIdGetterSetters,
    ParentChildTreeAlgebra<BlockId> parentChildTree,
  ) =>
      Resource.eval(() async {
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
            dataStores.transactions.getOrRaise,
            transactionAuthorizationValidation);
        final mempool = Mempool(
            dataStores.bodies.getOrRaise,
            parentChildTree,
            await currentEventIdGetterSetters.mempool.get(),
            Duration(minutes: 5));
        return Ledger(
            transactionSyntaxValidation: transactionSyntaxValidation,
            transactionSemanticValidation: transactionSemanticValidation,
            transactionAuthorizationValidation:
                transactionAuthorizationValidation,
            bodySyntaxValidation: bodySyntaxValidation,
            bodySemanticValidation: bodySemanticValidation,
            bodyAuthorizationValidation: bodyAuthorizationValidation,
            boxState: boxState,
            mempool: mempool);
      });
}
