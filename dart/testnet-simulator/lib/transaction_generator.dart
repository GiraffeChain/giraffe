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

  Stream<Transaction> run(Duration period) =>
      _targets().parAsyncMap(64, (t) async {
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
      }).throttleTime(period);

  Stream<(Wallet sender, LockAddress recipient)> _targets() async* {
    var walletIndex = 0;
    _incIndex() => walletIndex = (walletIndex + 1) % wallets.length;
    while (true) {
      Wallet sender = wallets[walletIndex];
      Wallet recipient =
          wallets[walletIndex == 0 ? wallets.length - 1 : walletIndex - 1];
      _incIndex();
      yield (sender, recipient.defaultLockAddress);
    }
  }
}
