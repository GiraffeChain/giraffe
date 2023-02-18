import 'package:blockchain_protobuf/models/transaction.pb.dart';

abstract class EpochLedger<State> {
  State n1State;
  State n2State;
  int nEpoch;
  EpochLedger(this.n1State, this.n2State, this.nEpoch);

  Future<State> get init;
  Future<State> apply(State previousState, Stream<Transaction> transactions);
  Future<void> shift(Stream<Transaction> transactions) async {
    final nState = await apply(n1State, transactions);
    n2State = n1State;
    n1State = nState;
    nEpoch += 1;
  }

  State stateOfEpoch(int targetEpoch) {
    switch (nEpoch - targetEpoch) {
      case 2:
        {
          return n2State;
        }
      case 1:
        {
          return n1State;
        }
      default:
        throw new Exception("Illegal targetEpoch=$targetEpoch");
    }
  }
}
