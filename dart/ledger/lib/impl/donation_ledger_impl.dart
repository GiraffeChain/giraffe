import 'package:blockchain_ledger/epoch_ledger.dart';
import 'package:blockchain_protobuf/models/transaction.pb.dart';

typedef Address = List<int>;

typedef DonationsMap = Map<Address, BigInt>;

class DonationsEpochLedger extends EpochLedger<DonationsMap> {
  final Future<TransactionOutput> Function(TransactionOutputReference)
      getTransactionOutput;

  DonationsEpochLedger(this.getTransactionOutput);

  @override
  Future<DonationsMap> apply(
      DonationsMap previousState, Stream<Transaction> transactions) async {
    final halvedPreviousDonors = previousState
        .map((key, value) => MapEntry(key, value ~/ BigInt.from(2)));
    return await transactions
        .asyncMap((tx) => _donationsOf(tx, getTransactionOutput))
        .fold<DonationsMap>(halvedPreviousDonors,
            (base, donations) => _mergeBigIntMaps(base, donations));
  }

  @override
  Future<DonationsMap> get init => Future.value({});

  Future<DonationsMap> _donationsOf(
      Transaction transaction,
      Future<TransactionOutput> Function(TransactionOutputReference)
          getTransactionOutput) async {
    final values = <Address, BigInt>{};

    final spentOutputs = await Future.wait(transaction.inputs
        .map((input) => getTransactionOutput(input.spentTransactionOutput)));

    spentOutputs.where((o) => o.value.hasCoin() && o.hasDonation()).forEach(
        (output) => values[output.donation.from] =
            (values[output.donation.from] ?? BigInt.from(0)) -
                output.value.coin.quantityNum);

    transaction.outputs
        .where((o) => o.value.hasCoin() && o.hasDonation())
        .forEach((output) => values[output.donation.from] =
            (values[output.donation.from] ?? BigInt.from(0)) +
                output.value.coin.quantityNum);
    return values;
  }
}

typedef DonationChallengeVotes = Map<Challenge, BigInt>;

class DonationVotesLedger extends EpochLedger<DonationChallengeVotes> {
  final Future<TransactionOutput> Function(TransactionOutputReference)
      getTransactionOutput;

  DonationVotesLedger(this.getTransactionOutput);
  @override
  Future<DonationChallengeVotes> apply(DonationChallengeVotes previousState,
          Stream<Transaction> transactions) =>
      transactions
          .asyncMap((tx) => donationVotesOf(tx, getTransactionOutput))
          .fold<DonationChallengeVotes>(Map.of(previousState),
              (base, donations) => _mergeBigIntMaps(base, donations));

  @override
  Future<DonationChallengeVotes> get init => Future.value({});

  Future<DonationChallengeVotes> donationVotesOf(
      Transaction transaction,
      Future<TransactionOutput> Function(TransactionOutputReference)
          getTransactionOutput) async {
    final DonationChallengeVotes values = {};

    final spentOutputs = await Future.wait(transaction.inputs
        .map((input) => getTransactionOutput(input.spentTransactionOutput)));

    spentOutputs.where((o) => o.value.hasCoin() && o.hasDonation()).forEach(
        (output) => values[output.value.coin.donationChallengeVote] =
            (values[output.value.coin.donationChallengeVote] ??
                    BigInt.from(0)) -
                output.value.coin.quantityNum);

    transaction.outputs.where((o) => o.value.hasCoin()).forEach((output) =>
        values[output.value.coin.donationChallengeVote] =
            (values[output.value.coin.donationChallengeVote] ??
                    BigInt.from(0)) +
                output.value.coin.quantityNum);
    return values;
  }
}

Map<Key, BigInt> _mergeBigIntMaps<Key>(Map<Key, BigInt> a, Map<Key, BigInt> b) {
  final a1 = Map.of(a);
  b.forEach((key, value) {
    a1[key] = (a1[key] ?? BigInt.from(0)) + value;
  });
  return a1;
}

extension CoinBigIntOps on Value_Coin {
  BigInt get quantityNum => BigInt.parse(quantity);
}
