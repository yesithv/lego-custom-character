import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../character_editor/domain/entities/character.dart';
import '../../../character_editor/domain/repositories/character_repository.dart';
import '../../domain/repositories/score_repository.dart';
import 'ranking_event.dart';
import 'ranking_state.dart';

class RankingBloc extends Bloc<RankingEvent, RankingState> {
  final ScoreRepository repository;
  final CharacterRepository characterRepository;

  RankingBloc({
    required this.repository,
    required this.characterRepository,
  }) : super(const RankingState()) {
    on<LoadRanking>(_onLoad);
    on<SubmitScoreEvent>(_onSubmit);
  }

  /// Construye el mapa `nombre → apariencia` a partir de los personajes
  /// guardados. Si hay nombres repetidos gana el último (los datos del podio
  /// solo necesitan una apariencia por nombre).
  Future<Map<String, CharacterAppearance>> _loadAppearances() async {
    final characters = await characterRepository.getAllCharacters();
    return {for (final c in characters) c.name: c.appearance};
  }

  Future<void> _onLoad(LoadRanking event, Emitter<RankingState> emit) async {
    emit(state.copyWith(status: RankingStatus.loading, worldId: event.worldId));
    final scores = await repository.getTopScores(event.worldId);
    final appearances = await _loadAppearances();
    emit(state.copyWith(
      status: RankingStatus.ready,
      scores: scores,
      appearancesByName: appearances,
    ));
  }

  Future<void> _onSubmit(
      SubmitScoreEvent event, Emitter<RankingState> emit) async {
    await repository.submitScore(event.score);
    if (state.worldId == event.score.worldId) {
      final scores = await repository.getTopScores(event.score.worldId);
      final appearances = await _loadAppearances();
      emit(state.copyWith(scores: scores, appearancesByName: appearances));
    }
  }
}
