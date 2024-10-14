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

  Stream<Transaction> run(Duration period) =>
      _targets(period).parAsyncMap(4, (t) async {
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
      }).parAsyncMap(32, (t) async {
        final (transaction, client) = t;
        await client.broadcastTransaction(transaction);
        return transaction;
      });

  Stream<(Wallet, Wallet, BlockchainClient)> _targets(Duration period) =>
      Stream.value(0).asyncExpand((walletIndex) {
        _incIndex() => walletIndex = (walletIndex + 1) % wallets.length;
        return Stream.periodic(period).asyncMap((_) async {
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
          return (sender, recipient, client);
        });
      });
}
