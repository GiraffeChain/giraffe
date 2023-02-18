import 'package:blockchain_protobuf/models/transaction.pb.dart';

abstract class EpochLedger<State> {
  Future<State> get init;
  Future<State> apply(State previousState, Stream<Transaction> transactions);
}
