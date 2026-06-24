import 'package:hive/hive.dart';

import '../../domain/entities/score.dart';
import '../../domain/repositories/score_repository.dart';
import '../models/score_model.dart';

// To migrate to Firebase: create FirebaseScoreRepository implementing ScoreRepository,
// then replace this class with the Firebase one in injection.dart.
class ScoreLocalRepository implements ScoreRepository {
  final Box<ScoreModel> _box;
  static const _maxPerWorld = 20;

  ScoreLocalRepository(this._box);

  @override
  Future<void> submitScore(Score score) async {
    await _box.put(score.id, ScoreModel.fromEntity(score));
    _prune(score.worldId);
  }

  @override
  Future<List<Score>> getTopScores(String worldId, {int limit = 10}) async {
    final all = _box.values
        .where((m) => m.worldId == worldId)
        .map((m) => m.toEntity())
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    // Keep only the best run per character name
    final seen = <String>{};
    final deduped = <Score>[];
    for (final s in all) {
      final key = s.characterName.isEmpty ? s.id : s.characterName;
      if (seen.add(key)) deduped.add(s);
    }
    return deduped.take(limit).toList();
  }

  void _prune(String worldId) {
    final entries = _box.values
        .where((m) => m.worldId == worldId)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    if (entries.length > _maxPerWorld) {
      for (final stale in entries.skip(_maxPerWorld)) {
        stale.delete();
      }
    }
  }
}
