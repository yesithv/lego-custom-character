import 'package:equatable/equatable.dart';

import '../../domain/entities/score.dart';

enum RankingStatus { initial, loading, ready }

class RankingState extends Equatable {
  final RankingStatus status;
  final String worldId;
  final List<Score> scores;

  const RankingState({
    this.status = RankingStatus.initial,
    this.worldId = '',
    this.scores = const [],
  });

  RankingState copyWith({
    RankingStatus? status,
    String? worldId,
    List<Score>? scores,
  }) =>
      RankingState(
        status: status ?? this.status,
        worldId: worldId ?? this.worldId,
        scores: scores ?? this.scores,
      );

  @override
  List<Object?> get props => [status, worldId, scores];
}
