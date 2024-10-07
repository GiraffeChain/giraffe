import 'package:giraffe_protocol/src/blockchain/consensus/chain_selection.dart';
import 'package:giraffe_sdk/sdk.dart';

import '../block_id_tree.dart';
import '../common/clock.dart';
import '../store.dart';
import '../codecs.dart';
import 'block_heights.dart';
import 'local_chain.dart';

export 'eta_calculation.dart';
export 'leader_election_validation.dart';
export 'numeric_utils.dart';
export 'staker_tracker.dart';
export 'utils.dart';
export 'models/vrf_argument.dart';

class Consensus {
  final LocalChain localChain;
  final ChainSelection chainSelection;

  Consensus({required this.localChain, required this.chainSelection});

  static Future<Consensus> make(
      FullBlock genesis,
      Clock clock,
      DataStores dataStores,
      BlockIdTree blockIdTree,
      ProtocolSettings protocolSettings,
      EventIdGetterSetters getterSetters) async {
    final blockHeightsBSS = BlockHeights.make(
        dataStores.blockHeightIndex,
        await getterSetters.blockHeightTree.get(),
        blockIdTree,
        getterSetters.blockHeightTree.set,
        dataStores.headers.getOrRaise);
    final localChain = LocalChainImpl(
        genesis: genesis.header.id,
        head: await getterSetters.canonicalHead.get(),
        fetchHeader: dataStores.headers.getOrRaise,
        fetchBody: dataStores.bodies.getOrRaise,
        blockHeightsBSS: blockHeightsBSS,
        onAdopted: getterSetters.canonicalHead.set);
    final chainSelection = ChainSelectionImpl(
        kLookback: protocolSettings.chainSelectionKLookback,
        sWindow: protocolSettings.chainSelectionSWindow);
    return Consensus(localChain: localChain, chainSelection: chainSelection);
  }

  Future<void> close() async {
    await localChain.close();
  }
}
