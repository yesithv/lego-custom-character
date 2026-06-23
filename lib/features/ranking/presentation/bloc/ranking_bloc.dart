import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/score_repository.dart';
import 'ranking_event.dart';
import 'ranking_state.dart';

class RankingBloc extends Bloc<RankingEvent, RankingState> {
  final ScoreRepository repository;

  RankingBloc({required this.repository}) : super(const RankingState()) {
    on<LoadRanking>(_onLoad);
    on<SubmitScoreEvent>(_onSubmit);
  }

  Future<void> _onLoad(LoadRanking event, Emitter<RankingState> emit) async {
    emit(state.copyWith(status: RankingStatus.loading, worldId: event.worldId));
    final scores = await repository.getTopScores(event.worldId);
    emit(state.copyWith(status: RankingStatus.ready, scores: scores));
  }

  Future<void> _onSubmit(
      SubmitScoreEvent event, Emitter<RankingState> emit) async {
    await repository.submitScore(event.score);
    if (state.worldId == event.score.worldId) {
      final scores = await repository.getTopScores(event.score.worldId);
      emit(state.copyWith(scores: scores));
    }
  }
}
