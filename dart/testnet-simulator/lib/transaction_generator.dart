import 'dart:math';

import 'package:fixnum/fixnum.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:giraffe_testnet_simulator/droplets.dart';

class TransactionGenerator {
  final List<Wallet> wallets;
  final List<RelayDroplet> relays;
  final _random = Random();
  late final clients = relays
      .where((c) => c.region.startsWith("nyc"))
      .map((r) => r.client)
      .toList();

  TransactionGenerator({
    required this.wallets,
    required this.relays,
  });

  Stream<Transaction> run(double tps) =>
      Stream.periodic(Duration(milliseconds: (1000 / tps).round()))
          .asyncMap((_) => _nextTarget())
          .parAsyncMap(32, (t) async {
        final client = clients[_random.nextInt(clients.length)];
        final (sender, recipient) = t;
        await sender.update(client);
        final transaction = await sender.payAndAttest(
            client,
            Transaction(
              outputs: [
                TransactionOutput(
                  lockAddress: recipient,
                  quantity: Int64(500),
                )
              ],
            ));
        await client.broadcastTransaction(transaction);
        return transaction;
      });

  var _walletIndex = 0;
  _incIndex() => _walletIndex = (_walletIndex + 1) % wallets.length;
  Future<(Wallet, LockAddress)> _nextTarget() async {
    Wallet sender = wallets[_walletIndex];
    Wallet recipient =
        wallets[_walletIndex == 0 ? wallets.length - 1 : _walletIndex - 1];
    _incIndex();
    return (sender, recipient.defaultLockAddress);
  }
}
