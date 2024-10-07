import 'package:giraffe_protocol/src/blockchain/consensus/chain_selection.dart';

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
}
