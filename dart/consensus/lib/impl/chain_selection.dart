import 'package:blockchain_common/store.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

class ScoreBasedChainSelection {
  BlockId _canonicalHead;
  final Store<BlockId, double> _cumulativeScores;
  final Future<BlockId> Function(BlockId) _parentOf;
  final double defaultScore;

  ScoreBasedChainSelection(
    this._canonicalHead,
    this._cumulativeScores,
    this._parentOf,
    this.defaultScore,
  );

  BlockId get canonicalHead => _canonicalHead;

  Future<bool> assignScore(BlockId blockId, double score) async {
    double? ancestorScore = null;
    int unscoredBlocksCount = 0;
    BlockId current = blockId;
    while (ancestorScore == null) {
      final parent = await _parentOf(current);
      final maybeScore = await _cumulativeScores.get(parent);
      if (maybeScore == null) {
        current = parent;
        unscoredBlocksCount += 1;
      } else {
        ancestorScore = maybeScore;
      }
    }
    final candidateScore =
        ancestorScore + (unscoredBlocksCount * defaultScore) + score;
    await _cumulativeScores.set(blockId, candidateScore);
    if (candidateScore > (await _cumulativeScores.get(_canonicalHead))!) {
      _canonicalHead = blockId;
      return true;
    }
    return false;
  }
}
