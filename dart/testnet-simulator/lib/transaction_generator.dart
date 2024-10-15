import 'dart:math';

import 'package:fixnum/fixnum.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:rxdart/transformers.dart';

class TransactionGenerator {
  final List<Wallet> wallets;
  final List<BlockchainClient> clients;
  final _random = Random();

  TransactionGenerator({
    required this.wallets,
    required this.clients,
  });

  Stream<Transaction> run(Duration period) => _targets(period)
      .parAsyncMap(16, (t) async {
        final (sender, recipient, client) = t;
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
        return (transaction, client);
      })
      .throttleTime(period)
      .parAsyncMap(32, (t) async {
        final (transaction, client) = t;
        await client.broadcastTransaction(transaction);
        return transaction;
      });

  Stream<(Wallet, Wallet, BlockchainClient)> _targets(Duration period) async* {
    var walletIndex = 0;
    _incIndex() => walletIndex = (walletIndex + 1) % wallets.length;
    while (true) {
      final client = clients[_random.nextInt(clients.length)];
      Wallet sender = wallets[walletIndex];
      await sender.update(client);
      _incIndex();
      while (sender.liquidFunds < Int64(4000)) {
        sender = wallets[walletIndex];
        await sender.update(client);
        _incIndex();
      }
      var recipientIndex = _random.nextInt(wallets.length);
      while (recipientIndex == walletIndex) {
        recipientIndex = _random.nextInt(wallets.length);
      }
      final recipient = wallets[recipientIndex];
      yield (sender, recipient, client);
    }
  }
}
