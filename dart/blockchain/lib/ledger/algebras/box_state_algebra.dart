import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class BoxStateAlgebra {
  Future<bool> boxExistsAt(
      BlockId blockId, TransactionOutputReference outputReference);
}
