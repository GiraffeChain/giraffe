import 'package:blockchain_protobuf/models/core.pb.dart';

extension CoinBigIntOps on Value_Coin {
  BigInt get quantityNum => BigInt.parse(quantity);
}
