import 'package:blockchain/common/clock.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain/consensus/consensus.dart';
import 'package:blockchain/consensus/models/protocol_settings.dart';
import 'package:blockchain/data_stores.dart';
import 'package:blockchain/ledger/ledger.dart';
import 'package:blockchain/minting/block_packer.dart';
import 'package:blockchain/minting/block_producer.dart';
import 'package:blockchain/minting/operational_key_maker.dart';
import 'package:blockchain/minting/secure_store.dart';
import 'package:blockchain/minting/staking.dart';
import 'package:blockchain/minting/vrf_calculator.dart';
import 'package:blockchain/staker_initializer.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:rxdart/streams.dart';

class Minting {
  final BlockPackerAlgebra blockPacker;
  final BlockProducerAlgebra blockProducer;
  final OperationalKeyMakerAlgebra operationalKeyMaker;
  final SecureStoreAlgebra secureStore;
  final StakingAlgebra staking;
  final VrfCalculatorAlgebra vrfCalculator;

  Minting(
      {required this.blockPacker,
      required this.blockProducer,
      required this.operationalKeyMaker,
      required this.secureStore,
      required this.staking,
      required this.vrfCalculator});

  static Resource<Minting> make(
    ProtocolSettings protocolSettings,
    ClockAlgebra clock,
    Consensus consensus,
    Ledger ledger,
    DataStores dataStores,
    SlotData canonicalHeadSlotData,
    StakerInitializer stakerInitializer,
  ) =>
      Resource.eval(() async {
        final secureStore = InMemorySecureStore();
        final blockPacker = BlockPacker(
            ledger.mempool,
            dataStores.transactions.getOrRaise,
            dataStores.transactions.contains,
            BlockPacker.makeBodyValidator(
                ledger.bodySyntaxValidation,
                ledger.bodySemanticValidation,
                ledger.bodyAuthorizationValidation));

        final vrfCalculator = VrfCalculator(stakerInitializer.vrfKeyPair.sk,
            clock, consensus.leaderElectionValidation, protocolSettings);

        final operationalKeyMaker = await OperationalKeyMaker.init(
          canonicalHeadSlotData.slotId,
          protocolSettings.operationalPeriodLength,
          Int64(0),
          stakerInitializer.stakingAddress,
          secureStore,
          clock,
          vrfCalculator,
          consensus.etaCalculation,
          consensus.consensusValidationState,
          stakerInitializer.kesKeyPair.sk,
        );

        final staker = Staking(
          stakerInitializer.stakingAddress,
          stakerInitializer.vrfKeyPair.vk,
          operationalKeyMaker,
          consensus.consensusValidationState,
          consensus.etaCalculation,
          vrfCalculator,
          consensus.leaderElectionValidation,
        );

        final blockProducer = BlockProducer(
          ConcatStream([
            Stream.value(canonicalHeadSlotData).asyncMap(
                (d) => clock.delayedUntilSlot(d.slotId.slot).then((_) => d)),
            consensus.localChain.adoptions
                .asyncMap(dataStores.slotData.getOrRaise),
          ]),
          staker,
          clock,
          blockPacker,
        );

        return Minting(
            blockPacker: blockPacker,
            blockProducer: blockProducer,
            operationalKeyMaker: operationalKeyMaker,
            secureStore: secureStore,
            staking: staker,
            vrfCalculator: vrfCalculator);
      });
}
