import 'package:blockchain/common/clock.dart';
import 'package:blockchain/common/parent_child_tree.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain/consensus/local_chain.dart';
import 'package:blockchain/data_stores.dart';
import 'package:blockchain/ledger/block_header_to_body_validation.dart';
import 'package:blockchain/ledger/block_packer.dart';
import 'package:blockchain/ledger/body_validation.dart';
import 'package:blockchain/ledger/transaction_output_state.dart';
import 'package:blockchain/ledger/mempool.dart';
import 'package:blockchain/ledger/transaction_validation.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

class Ledger {
  final TransactionSyntaxValidation transactionSyntaxValidation;
  final TransactionSemanticValidation transactionSemanticValidation;
  final BodyValidation bodyValidation;
  final BlockHeaderToBodyValidation headerToBodyValidation;
  final TransactionOutputState transactionOutputState;
  final MempoolImpl mempool;
  final BlockPackerImpl blockPacker;

  Ledger({
    required this.transactionSyntaxValidation,
    required this.transactionSemanticValidation,
    required this.bodyValidation,
    required this.headerToBodyValidation,
    required this.transactionOutputState,
    required this.mempool,
    required this.blockPacker,
  });

  static Resource<Ledger> make(
    DataStores dataStores,
    CurrentEventIdGetterSetters currentEventIdGetterSetters,
    ParentChildTree<BlockId> parentChildTree,
    Clock clock,
    LocalChain localChain,
  ) =>
      Resource.eval(() async => TransactionOutputStateImpl.make(
                dataStores.spendableTransactionOutputs,
                await currentEventIdGetterSetters.transactionOutputs.get(),
                dataStores.bodies.getOrRaise,
                dataStores.transactions.getOrRaise,
                parentChildTree,
                currentEventIdGetterSetters.transactionOutputs.set,
              ))
          .flatTap((transactionOutputState) =>
              transactionOutputState.eventSourcedState.followChain(localChain))
          .evalFlatMap((transactionOutputState) async {
        final transactionSyntaxValidation = TransactionSyntaxValidationImpl();
        final transactionSemanticValidation = TransactionSemanticValidationImpl(
            dataStores.transactions.getOrRaise, transactionOutputState);
        final bodyValidation = BodyValidationImpl(
          fetchTransaction: dataStores.transactions.getOrRaise,
          transactionSyntaxValidation: transactionSyntaxValidation,
          transactionSemanticValidation: transactionSemanticValidation,
        );

        final headerToBodyValidation = BlockHeaderToBodyValidationImpl(
            fetchHeader: dataStores.headers.getOrRaise);
        return MempoolImpl.make(
                dataStores.bodies.getOrRaise,
                parentChildTree,
                await currentEventIdGetterSetters.mempool.get(),
                Duration(minutes: 5))
            .flatTap(
                (mempool) => mempool.eventSourcedState.followChain(localChain))
            .map((mempool) {
          final blockPacker = BlockPackerImpl(
            mempool,
            clock,
            dataStores.transactions.getOrRaise,
            dataStores.transactions.contains,
            BlockPackerImpl.makeBodyValidator(bodyValidation),
          );
          return Ledger(
            transactionSyntaxValidation: transactionSyntaxValidation,
            transactionSemanticValidation: transactionSemanticValidation,
            bodyValidation: bodyValidation,
            headerToBodyValidation: headerToBodyValidation,
            transactionOutputState: transactionOutputState,
            mempool: mempool,
            blockPacker: blockPacker,
          );
        });
      });
}
