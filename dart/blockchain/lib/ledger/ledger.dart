import 'package:blockchain/common/clock.dart';
import 'package:blockchain/common/parent_child_tree.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain/data_stores.dart';
import 'package:blockchain/ledger/block_header_to_body_validation.dart';
import 'package:blockchain/ledger/block_packer.dart';
import 'package:blockchain/ledger/body_semantic_validation.dart';
import 'package:blockchain/ledger/body_syntax_validation.dart';
import 'package:blockchain/ledger/box_state.dart';
import 'package:blockchain/ledger/mempool.dart';
import 'package:blockchain/ledger/transaction_semantic_validation.dart';
import 'package:blockchain/ledger/transaction_syntax_validation.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

class Ledger {
  final TransactionSyntaxValidation transactionSyntaxValidation;
  final TransactionSemanticValidation transactionSemanticValidation;
  final BodySyntaxValidation bodySyntaxValidation;
  final BodySemanticValidation bodySemanticValidation;
  final BlockHeaderToBodyValidation headerToBodyValidation;
  final BoxState boxState;
  final MempoolImpl mempool;
  final BlockPackerImpl blockPacker;

  Ledger({
    required this.transactionSyntaxValidation,
    required this.transactionSemanticValidation,
    required this.bodySyntaxValidation,
    required this.bodySemanticValidation,
    required this.headerToBodyValidation,
    required this.boxState,
    required this.mempool,
    required this.blockPacker,
  });

  static Resource<Ledger> make(
    DataStores dataStores,
    CurrentEventIdGetterSetters currentEventIdGetterSetters,
    ParentChildTree<BlockId> parentChildTree,
    Clock clock,
  ) =>
      Resource.pure(()).evalFlatMap((_) async {
        final boxState = BoxStateImpl.make(
          dataStores.spendableBoxIds,
          await currentEventIdGetterSetters.boxState.get(),
          dataStores.bodies.getOrRaise,
          dataStores.transactions.getOrRaise,
          parentChildTree,
          currentEventIdGetterSetters.boxState.set,
        );

        final transactionSyntaxValidation = TransactionSyntaxValidationImpl();
        final transactionSemanticValidation = TransactionSemanticValidationImpl(
            dataStores.transactions.getOrRaise, boxState);
        final bodySyntaxValidation = BodySyntaxValidationImpl(
            dataStores.transactions.getOrRaise, transactionSyntaxValidation);
        final bodySemanticValidation = BodySemanticValidationImpl(
            dataStores.transactions.getOrRaise, transactionSemanticValidation);

        final headerToBodyValidation = BlockHeaderToBodyValidationImpl(
            fetchHeader: dataStores.headers.getOrRaise);
        return MempoolImpl.make(
                dataStores.bodies.getOrRaise,
                parentChildTree,
                await currentEventIdGetterSetters.mempool.get(),
                Duration(minutes: 5))
            .map((mempool) {
          final blockPacker = BlockPackerImpl(
            mempool,
            clock,
            dataStores.transactions.getOrRaise,
            dataStores.transactions.contains,
            BlockPackerImpl.makeBodyValidator(
                bodySyntaxValidation, bodySemanticValidation),
          );
          return Ledger(
            transactionSyntaxValidation: transactionSyntaxValidation,
            transactionSemanticValidation: transactionSemanticValidation,
            bodySyntaxValidation: bodySyntaxValidation,
            bodySemanticValidation: bodySemanticValidation,
            headerToBodyValidation: headerToBodyValidation,
            boxState: boxState,
            mempool: mempool,
            blockPacker: blockPacker,
          );
        });
      });
}
