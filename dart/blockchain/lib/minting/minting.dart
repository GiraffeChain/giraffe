import 'dart:io';

import 'package:blockchain/common/clock.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain/consensus/consensus.dart';
import 'package:blockchain/consensus/models/protocol_settings.dart';
import 'package:blockchain/data_stores.dart';
import 'package:blockchain/ledger/ledger.dart';
import 'package:blockchain/minting/block_producer.dart';
import 'package:blockchain/minting/secure_store.dart';
import 'package:blockchain/minting/staking.dart';
import 'package:blockchain/minting/vrf_calculator.dart';
import 'package:blockchain/staker_initializer.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:rxdart/streams.dart';

class Minting {
  final BlockProducer blockProducer;
  final SecureStore secureStore;
  final Staking staking;
  final VrfCalculator vrfCalculator;

  Minting({
    required this.blockProducer,
    required this.secureStore,
    required this.staking,
    required this.vrfCalculator,
  });

  static Resource<Minting> make(
    ProtocolSettings protocolSettings,
    Clock clock,
    Consensus consensus,
    Ledger ledger,
    DataStores dataStores,
    SlotData canonicalHeadSlotData,
    StakerInitializer stakerInitializer,
  ) =>
      Resource.eval(() => Directory.systemTemp.createTemp("secure-store"))
          .map((stakingDir) => DiskSecureStore(baseDir: stakingDir))
          .flatMap((secureStore) {
        final vrfCalculator = VrfCalculatorImpl(stakerInitializer.vrfKeyPair.sk,
            clock, consensus.leaderElection, protocolSettings);

        return StakingImpl.make(
          canonicalHeadSlotData.slotId,
          protocolSettings.operationalPeriodLength,
          Int64(0),
          stakerInitializer.stakingAddress,
          stakerInitializer.kesKeyPair.sk,
          stakerInitializer.vrfKeyPair.vk,
          secureStore,
          clock,
          vrfCalculator,
          consensus.etaCalculation,
          consensus.stakerTracker,
          consensus.leaderElection,
        ).map((staking) {
          final blockProducer = BlockProducerImpl(
            ConcatStream([
              Stream.value(canonicalHeadSlotData).asyncMap(
                  (d) => clock.delayedUntilSlot(d.slotId.slot).then((_) => d)),
              consensus.localChain.adoptions
                  .asyncMap(dataStores.slotData.getOrRaise),
            ]),
            staking,
            clock,
            ledger.blockPacker,
          );

          return Minting(
            blockProducer: blockProducer,
            secureStore: secureStore,
            staking: staking,
            vrfCalculator: vrfCalculator,
          );
        });
      });
}
