import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class BlockProducerAlgebra {
  Stream<FullBlock> get blocks;
}
