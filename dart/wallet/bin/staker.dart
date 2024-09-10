import 'dart:io';

import 'package:args/args.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:giraffe_wallet/blockchain/common/clock.dart';
import 'package:giraffe_wallet/blockchain/common/isolate_pool.dart';
import 'package:giraffe_wallet/blockchain/consensus/eta_calculation.dart';
import 'package:giraffe_wallet/blockchain/consensus/leader_election_validation.dart';
import 'package:giraffe_wallet/blockchain/consensus/staker_tracker.dart';
import 'package:giraffe_wallet/blockchain/ledger/block_packer.dart';
import 'package:giraffe_wallet/blockchain/minting/block_producer.dart';
import 'package:giraffe_wallet/blockchain/minting/models/staker_data.dart';
import 'package:giraffe_wallet/blockchain/minting/staking.dart';
import 'package:giraffe_wallet/blockchain/minting/vrf_calculator.dart';
import 'package:giraffe_wallet/blockchain/private_testnet.dart';
import 'package:logging/logging.dart';

void main(List<String> args) async {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print(
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}${record.error ?? ""}${record.stackTrace != null ? "\n${record.stackTrace}" : ""}');
  });
  final computePool = IsolatePool(Platform.numberOfProcessors);
  setComputeFunction(computePool.isolate);
  final parsedArgs = argParser.parse(args);
  final apiAddress = parsedArgs.option("api-address")!;
  final stakerData = StakerData.deserialize(parsedArgs.option("staker-data")!);
  final rewardAddressStr = parsedArgs.option("reward-address");
  final LockAddress rewardAddress;
  if (rewardAddressStr != null) {
    rewardAddress = decodeLockAddress(rewardAddressStr);
  } else {
    rewardAddress = await PrivateTestnet.defaultLockAddress;
    log.warning(
        "Reward address not specified. Using public wallet address: ${rewardAddress.show}");
  }

  final client = BlockchainClientFromJsonRpc(baseAddress: apiAddress);

  final accountOutput = await client.getTransactionOutput(stakerData.account);
  if (accountOutput == null) {
    throw Exception("Account not found on the chain");
  }
  assert(accountOutput.value.hasAccountRegistration(),
      "Specified UTxO is not an account registration");

  final canonicalHeadId = await client.canonicalHeadId;
  final canonicalHead = await client.getBlockHeaderOrRaise(canonicalHeadId);
  log.info(
      "Canonical head id=${canonicalHeadId.show} height=${canonicalHead.height} slot=${canonicalHead.slot}");
  final protocolSettings = await client.protocolSettings;

  final genesisBlockId = await client.genesisBlockId;
  final genesisHeader = await client.getBlockHeaderOrRaise(genesisBlockId);
  log.info(
      "Genesis id=${genesisBlockId.show} height=${genesisHeader.height} slot=${genesisHeader.slot}");
  final clock = ClockImpl(
    protocolSettings.slotDuration,
    protocolSettings.epochLength,
    genesisHeader.timestamp,
  );
  final leaderElection = LeaderElectionImpl(protocolSettings, isolate);

  final vrfCalculator = VrfCalculatorImpl(
      stakerData.vrfSk, clock, leaderElection, protocolSettings);
  final vrfVk = await ed25519Vrf.getVerificationKey(stakerData.vrfSk);

  final staking = StakingImpl(
    stakerData.account,
    vrfVk,
    stakerData.operatorSk,
    StakerTrackerForStakerSupportRpc(client: client),
    EtaCalculationForStakerSupportRpc(client: client),
    vrfCalculator,
    leaderElection,
  );

  final blockProducer = BlockProducerImpl(
    staking,
    clock,
    BlockPackerForStakerSupportRpc(client: client),
    rewardAddress,
  );

  Future<void> Function() cancel = () => Future.value();

  void handle(BlockHeader h) async {
    await cancel();
    final sub = blockProducer
        .makeChild(h)
        .asyncMap((b) => client.broadcastBlock(
              Block(
                header: b.header,
                body: BlockBody(
                    transactionIds: b.fullBody.transactions.map((t) => t.id)),
              ),
              b.fullBody.rewardTransaction,
            ))
        .listen(null);
    cancel = () => sub.cancel();
  }

  handle(canonicalHead);
  await client.adoptions.asyncMap(client.getBlockHeaderOrRaise).forEach(handle);
}

final log = Logger("staker");

ArgParser get argParser {
  final parser = ArgParser();
  parser.addOption("api-address",
      abbr: "a",
      help:
          "The API address of a Giraffe relay node (i.e. http://localhost:2024/api)",
      mandatory: true);
  parser.addOption("staker-data",
      abbr: "s",
      help: "The string-encoded staker data, provided by the wallet",
      mandatory: true);
  parser.addOption("reward-address",
      abbr: "r",
      help:
          "The address to which rewards should be sent. If not provided, rewards are sent to the public wallet.",
      mandatory: false);
  return parser;
}
