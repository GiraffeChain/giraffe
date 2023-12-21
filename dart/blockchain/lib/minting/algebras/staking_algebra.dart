import 'package:blockchain/common/models/unsigned.dart';
import 'package:blockchain/minting/models/vrf_hit.dart';
import 'package:fixnum/fixnum.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class StakingAlgebra {
  StakingAddress get address;
  Future<VrfHit?> elect(SlotId parentSlotId, Int64 slot);
  Future<BlockHeader?> certifyBlock(
      SlotId parentSlotId,
      Int64 slot,
      UnsignedBlockHeader Function(PartialOperationalCertificate)
          unsignedBlockBuilder);
}
