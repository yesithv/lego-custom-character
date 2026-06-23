import 'package:hive/hive.dart';

import '../../domain/entities/score.dart';

part 'score_model.g.dart';

@HiveType(typeId: 3)
class ScoreModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String characterName;

  @HiveField(2)
  late String worldId;

  @HiveField(3)
  late int score;

  @HiveField(4)
  late int meters;

  @HiveField(5)
  late int coins;

  @HiveField(6)
  late int createdAtMs;

  Score toEntity() => Score(
        id: id,
        characterName: characterName,
        worldId: worldId,
        score: score,
        meters: meters,
        coins: coins,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      );

  static ScoreModel fromEntity(Score s) => ScoreModel()
    ..id = s.id
    ..characterName = s.characterName
    ..worldId = s.worldId
    ..score = s.score
    ..meters = s.meters
    ..coins = s.coins
    ..createdAtMs = s.createdAt.millisecondsSinceEpoch;
}
