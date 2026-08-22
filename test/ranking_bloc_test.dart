import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:run_for_win/features/character_editor/domain/entities/character.dart';
import 'package:run_for_win/features/character_editor/domain/repositories/character_repository.dart';
import 'package:run_for_win/features/ranking/domain/entities/score.dart';
import 'package:run_for_win/features/ranking/domain/repositories/score_repository.dart';
import 'package:run_for_win/features/ranking/presentation/bloc/ranking_bloc.dart';
import 'package:run_for_win/features/ranking/presentation/bloc/ranking_event.dart';
import 'package:run_for_win/features/ranking/presentation/bloc/ranking_state.dart';

class _MockScoreRepo extends Mock implements ScoreRepository {}

class _MockCharacterRepo extends Mock implements CharacterRepository {}

Score _score(String world, int pts) => Score(
      id: '$world-$pts',
      characterName: 'Brix',
      worldId: world,
      score: pts,
      meters: pts,
      coins: 0,
      createdAt: DateTime(2026, 1, 1),
    );

Character _char(String name) => Character(
      id: name,
      name: name,
      type: CharacterType.hero,
      appearance: const CharacterAppearance(),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  late _MockScoreRepo scoreRepo;
  late _MockCharacterRepo charRepo;

  setUpAll(() {
    registerFallbackValue(_score('brix_city', 0));
  });

  setUp(() {
    scoreRepo = _MockScoreRepo();
    charRepo = _MockCharacterRepo();
  });

  RankingBloc build() =>
      RankingBloc(repository: scoreRepo, characterRepository: charRepo);

  blocTest<RankingBloc, RankingState>(
    'LoadRanking carga scores y apariencias',
    build: () {
      when(() => scoreRepo.getTopScores('brix_city'))
          .thenAnswer((_) async => [_score('brix_city', 500)]);
      when(() => charRepo.getAllCharacters())
          .thenAnswer((_) async => [_char('Brix')]);
      return build();
    },
    act: (b) => b.add(const LoadRanking('brix_city')),
    expect: () => [
      isA<RankingState>()
          .having((s) => s.status, 'status', RankingStatus.loading)
          .having((s) => s.worldId, 'worldId', 'brix_city'),
      isA<RankingState>()
          .having((s) => s.status, 'status', RankingStatus.ready)
          .having((s) => s.scores.length, 'scores', 1)
          .having((s) => s.appearancesByName.containsKey('Brix'),
              'appearances', true),
    ],
  );

  blocTest<RankingBloc, RankingState>(
    'LoadRanking sin puntuaciones queda ready con lista vacía',
    build: () {
      when(() => scoreRepo.getTopScores('galaxy'))
          .thenAnswer((_) async => <Score>[]);
      when(() => charRepo.getAllCharacters())
          .thenAnswer((_) async => <Character>[]);
      return build();
    },
    act: (b) => b.add(const LoadRanking('galaxy')),
    expect: () => [
      isA<RankingState>()
          .having((s) => s.status, 'status', RankingStatus.loading),
      isA<RankingState>()
          .having((s) => s.status, 'status', RankingStatus.ready)
          .having((s) => s.scores, 'scores', isEmpty),
    ],
  );

  blocTest<RankingBloc, RankingState>(
    'SubmitScore del mundo actual reenvía y recarga la tabla',
    build: () {
      when(() => scoreRepo.submitScore(any())).thenAnswer((_) async {});
      when(() => scoreRepo.getTopScores('brix_city'))
          .thenAnswer((_) async => [_score('brix_city', 900)]);
      when(() => charRepo.getAllCharacters())
          .thenAnswer((_) async => [_char('Brix')]);
      return build();
    },
    seed: () => const RankingState(
      status: RankingStatus.ready,
      worldId: 'brix_city',
    ),
    act: (b) => b.add(SubmitScoreEvent(_score('brix_city', 900))),
    verify: (_) {
      verify(() => scoreRepo.submitScore(any())).called(1);
      verify(() => scoreRepo.getTopScores('brix_city')).called(1);
    },
    expect: () => [
      isA<RankingState>().having((s) => s.scores.first.score, 'top', 900),
    ],
  );

  blocTest<RankingBloc, RankingState>(
    'SubmitScore de otro mundo solo persiste, no recarga ni emite',
    build: () {
      when(() => scoreRepo.submitScore(any())).thenAnswer((_) async {});
      return build();
    },
    seed: () => const RankingState(
      status: RankingStatus.ready,
      worldId: 'brix_city',
    ),
    act: (b) => b.add(SubmitScoreEvent(_score('galaxy', 300))),
    verify: (_) {
      verify(() => scoreRepo.submitScore(any())).called(1);
      verifyNever(() => scoreRepo.getTopScores(any()));
    },
    expect: () => const <RankingState>[],
  );
}
