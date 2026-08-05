import 'package:equatable/equatable.dart';

import '../../../character_editor/domain/entities/character.dart';
import '../../domain/entities/score.dart';

enum RankingStatus { initial, loading, ready }

class RankingState extends Equatable {
  final RankingStatus status;
  final String worldId;
  final List<Score> scores;

  /// Apariencia de cada personaje del jugador indexada por nombre. Permite
  /// dibujar la figura real (podio) sin que `Score` guarde la apariencia; se
  /// resuelve cruzando `Score.characterName` con los personajes guardados.
  final Map<String, CharacterAppearance> appearancesByName;

  const RankingState({
    this.status = RankingStatus.initial,
    this.worldId = '',
    this.scores = const [],
    this.appearancesByName = const {},
  });

  RankingState copyWith({
    RankingStatus? status,
    String? worldId,
    List<Score>? scores,
    Map<String, CharacterAppearance>? appearancesByName,
  }) =>
      RankingState(
        status: status ?? this.status,
        worldId: worldId ?? this.worldId,
        scores: scores ?? this.scores,
        appearancesByName: appearancesByName ?? this.appearancesByName,
      );

  @override
  List<Object?> get props => [status, worldId, scores, appearancesByName];
}
