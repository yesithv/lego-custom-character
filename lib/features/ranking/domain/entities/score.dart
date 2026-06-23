import 'package:equatable/equatable.dart';

class Score extends Equatable {
  final String id;
  final String characterName;
  final String worldId;
  final int score;
  final int meters;
  final int coins;
  final DateTime createdAt;

  const Score({
    required this.id,
    required this.characterName,
    required this.worldId,
    required this.score,
    required this.meters,
    required this.coins,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, worldId, score, createdAt];
}
