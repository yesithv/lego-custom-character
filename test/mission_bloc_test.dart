import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/features/missions/domain/entities/mission.dart';
import 'package:run_for_win/features/missions/domain/repositories/mission_repository.dart';
import 'package:run_for_win/features/missions/presentation/bloc/mission_bloc.dart';
import 'package:run_for_win/features/missions/presentation/bloc/mission_event.dart';
import 'package:run_for_win/features/missions/presentation/bloc/mission_state.dart';

/// Fake configurable del repositorio de misiones.
class _FakeMissionRepo implements MissionRepository {
  List<Mission> active;
  List<Mission> advanced;
  List<Mission> refreshed;
  _FakeMissionRepo({
    this.active = const [],
    this.advanced = const [],
    this.refreshed = const [],
  });

  @override
  Future<List<Mission>> getActiveMissions() async => active;
  @override
  Future<List<Mission>> advanceMissions(MissionRunData data) async => advanced;
  @override
  Future<List<Mission>> refreshMissions() async => refreshed;
}

Mission _m(String id, {required int progress, int target = 100}) => Mission(
      id: id,
      type: MissionType.collectCoins,
      title: 'Recoge monedas',
      description: 'x',
      target: target,
      progress: progress,
      rewardCoins: 50,
    );

const _runData = MissionRunData(
  coins: 100,
  meters: 100,
  evadedObstacles: 0,
  seconds: 0,
  jumps: 0,
);

void main() {
  blocTest<MissionBloc, MissionState>(
    'LoadMissions emite loading y luego ready con las misiones',
    build: () =>
        MissionBloc(repository: _FakeMissionRepo(active: [_m('a', progress: 0)])),
    act: (b) => b.add(const LoadMissions()),
    expect: () => [
      isA<MissionState>()
          .having((s) => s.status, 'status', MissionStatus.loading),
      isA<MissionState>()
          .having((s) => s.status, 'status', MissionStatus.ready)
          .having((s) => s.missions.length, 'missions', 1),
    ],
  );

  blocTest<MissionBloc, MissionState>(
    'AdvanceMissions marca como recién completadas las que pasan a completas',
    build: () => MissionBloc(
      repository: _FakeMissionRepo(advanced: [_m('a', progress: 100)]),
    ),
    seed: () => MissionState(
      status: MissionStatus.ready,
      missions: [_m('a', progress: 40)],
    ),
    act: (b) => b.add(const AdvanceMissionsEvent(_runData)),
    expect: () => [
      isA<MissionState>()
          .having((s) => s.justCompleted.map((m) => m.id).toList(),
              'justCompleted', ['a'])
          .having((s) => s.missions.first.isCompleted, 'completa', true),
    ],
  );

  blocTest<MissionBloc, MissionState>(
    'AdvanceMissions no marca nada si ninguna cruza a completa',
    build: () => MissionBloc(
      repository: _FakeMissionRepo(advanced: [_m('a', progress: 60)]),
    ),
    seed: () => MissionState(
      status: MissionStatus.ready,
      missions: [_m('a', progress: 40)],
    ),
    act: (b) => b.add(const AdvanceMissionsEvent(_runData)),
    expect: () => [
      isA<MissionState>()
          .having((s) => s.justCompleted, 'justCompleted', isEmpty),
    ],
  );

  blocTest<MissionBloc, MissionState>(
    'RefreshMissions reemplaza misiones y limpia justCompleted',
    build: () => MissionBloc(
      repository: _FakeMissionRepo(refreshed: [_m('nueva', progress: 0)]),
    ),
    seed: () => MissionState(
      status: MissionStatus.ready,
      missions: [_m('vieja', progress: 100)],
      justCompleted: [_m('vieja', progress: 100)],
    ),
    act: (b) => b.add(const RefreshMissionsEvent()),
    expect: () => [
      isA<MissionState>()
          .having((s) => s.missions.map((m) => m.id).toList(), 'missions',
              ['nueva'])
          .having((s) => s.justCompleted, 'justCompleted', isEmpty),
    ],
  );
}
