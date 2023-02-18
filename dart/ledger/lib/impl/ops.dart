import 'package:blockchain_protobuf/models/transaction.pb.dart';

extension CoinBigIntOps on Value_Coin {
  BigInt get quantityNum => BigInt.parse(quantity);
}
