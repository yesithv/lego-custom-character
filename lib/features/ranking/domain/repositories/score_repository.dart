import '../entities/score.dart';

/// Contrato del ranking. En el MVP v1 la única implementación es
/// [ScoreLocalRepository] (Hive, sin red). El contrato se mantiene abstracto
/// para poder añadir un ranking en línea más adelante sin tocar la UI: bastaría
/// otra implementación y cambiar el registro en injection.dart.
abstract class ScoreRepository {
  Future<void> submitScore(Score score);
  Future<List<Score>> getTopScores(String worldId, {int limit = 10});
}
