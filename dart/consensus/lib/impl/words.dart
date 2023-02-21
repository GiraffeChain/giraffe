import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:crypto/crypto.dart';

List<String> words = [
  "fish",
  "heart",
  "phone",
  "shirt",
  "guitar",
  "ladder",
  "swim",
  "circle",
  "triangle",
  "big",
  "small",
  "wide",
  "narrow",
  "loud",
  "happy",
  "sad",
  "funny"
];

Set<String> pseudoRandomWords(BlockId parentBlockId, Account rewardsAccount) {
  final h = sha256
      .convert([]
        ..addAll(parentBlockId.bytes)
        ..addAll(rewardsAccount.id))
      .bytes;
  final s1 = words[h.first % words.length];
  final s2 = words[h.last % words.length];
  return {s1, s2};
}
