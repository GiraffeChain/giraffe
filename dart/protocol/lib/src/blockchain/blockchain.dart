export 'common/common.dart';
export 'consensus/consensus.dart';
export 'ledger/ledger.dart';
export 'minting/minting.dart';
export 'p2p/p2p.dart';
export 'codecs.dart';
export 'genesis.dart';
export 'private_testnet.dart';
export 'staking_account.dart';
import 'package:giraffe_sdk/sdk.dart';

import 'block_id_tree.dart';
import 'common/clock.dart';
import 'consensus/consensus.dart';
import 'store.dart';

class BlockchainCore {
  final ProtocolSettings protocolSettings;
  final Clock clock;
  final DataStores dataStores;
  final BlockIdTree blockIdTree;
  final Consensus consensus;

  BlockchainCore({
    required this.protocolSettings,
    required this.clock,
    required this.dataStores,
    required this.blockIdTree,
    required this.consensus,
  });
}
