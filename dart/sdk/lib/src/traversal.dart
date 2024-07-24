import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class TraversalStep {
  final BlockId blockId;

  TraversalStep(this.blockId);
}

class TraversalStep_Applied extends TraversalStep {
  TraversalStep_Applied(super.blockId);
}

class TraversalStep_Unapplied extends TraversalStep {
  TraversalStep_Unapplied(super.blockId);
}
