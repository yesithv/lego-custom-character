import 'package:equatable/equatable.dart';

import '../../domain/entities/score.dart';

sealed class RankingEvent extends Equatable {
  const RankingEvent();
  @override
  List<Object?> get props => [];
}

class LoadRanking extends RankingEvent {
  final String worldId;
  const LoadRanking(this.worldId);
  @override
  List<Object?> get props => [worldId];
}

class SubmitScoreEvent extends RankingEvent {
  final Score score;
  const SubmitScoreEvent(this.score);
  @override
  List<Object?> get props => [score];
}
