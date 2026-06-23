class RunSession {
  final int score;
  final int coins;
  final int meters;
  final double multiplier;
  final int obstacleStreak;
  final String worldId;

  const RunSession({
    this.score = 0,
    this.coins = 0,
    this.meters = 0,
    this.multiplier = 1.0,
    this.obstacleStreak = 0,
    required this.worldId,
  });

  RunSession copyWith({
    int? score,
    int? coins,
    int? meters,
    double? multiplier,
    int? obstacleStreak,
  }) =>
      RunSession(
        score: score ?? this.score,
        coins: coins ?? this.coins,
        meters: meters ?? this.meters,
        multiplier: multiplier ?? this.multiplier,
        obstacleStreak: obstacleStreak ?? this.obstacleStreak,
        worldId: worldId,
      );
}
