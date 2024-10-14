import 'dart:math';

import 'package:fixnum/fixnum.dart';
import 'package:giraffe_sdk/sdk.dart';

class TransactionGenerator {
  final List<Wallet> wallets;
  final List<BlockchainClient> clients;
  final _random = Random();

  TransactionGenerator({
    required this.wallets,
    required this.clients,
  });

  Stream<Transaction> run(Duration period) async* {
    var _walletIndex = 0;
    _incIndex() => _walletIndex = (_walletIndex + 1) % wallets.length;

    while (true) {
      final start = DateTime.now();
      final client = clients[_random.nextInt(clients.length)];
      Wallet sender = wallets[_walletIndex];
      await sender.update(client);
      _incIndex();
      while (sender.liquidFunds < Int64(4000)) {
        sender = wallets[_walletIndex];
        await sender.update(client);
        _incIndex();
      }
      var recipientIndex = _random.nextInt(wallets.length);
      while (recipientIndex == _walletIndex) {
        recipientIndex = _random.nextInt(wallets.length);
      }
      final recipient = wallets[recipientIndex];
      await sender.update(client);
      final transaction = await sender.payAndAttest(
          client,
          Transaction(
            outputs: [
              TransactionOutput(
                lockAddress: recipient.defaultLockAddress,
                quantity: Int64(1000),
              )
            ],
          ));
      await client.broadcastTransaction(transaction);
      yield transaction;
      await Future.delayed(period - DateTime.now().difference(start));
    }
  }
}
