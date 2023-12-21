import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class BlockHeadervalidationAlgebra {
  /**
   * Indicates if the claimed child is a valid descendent of the parent
   */
  Future<List<String>> validate(BlockHeader header);
}
