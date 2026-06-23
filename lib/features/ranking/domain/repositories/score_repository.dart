import '../entities/score.dart';

/// Extension point: implement FirebaseScoreRepository with this same interface,
/// then swap the binding in injection.dart — zero other changes needed.
abstract class ScoreRepository {
  Future<void> submitScore(Score score);
  Future<List<Score>> getTopScores(String worldId, {int limit = 10});
}
