import 'dart:convert';
import 'dart:math';

import '../../domain/entities/mission.dart';
import '../../domain/repositories/mission_repository.dart';
import '../datasources/mission_local_datasource.dart';

// (type, target, title, description, rewardCoins)
const _templates = [
  (MissionType.collectCoins, 10, 'Recolector', 'Recoge 10 monedas en una carrera', 50),
  (MissionType.collectCoins, 25, 'Ahorrador', 'Recoge 25 monedas en una carrera', 100),
  (MissionType.collectCoins, 50, 'Rico Rico', 'Recoge 50 monedas en una carrera', 200),
  (MissionType.runMeters, 200, 'Corredor', 'Corre 200 metros en una carrera', 50),
  (MissionType.runMeters, 500, 'Maratonista', 'Corre 500 metros en una carrera', 100),
  (MissionType.runMeters, 1000, 'Velocista', 'Corre 1000 metros en una carrera', 200),
  (MissionType.evadeObstacles, 5, 'Esquivador', 'Esquiva 5 obstáculos seguidos', 50),
  (MissionType.evadeObstacles, 10, 'Ninja', 'Esquiva 10 obstáculos seguidos', 100),
  (MissionType.evadeObstacles, 20, 'Fantasma', 'Esquiva 20 obstáculos seguidos', 200),
  (MissionType.surviveSeconds, 30, 'Resistente', 'Sobrevive 30 segundos en una carrera', 75),
  (MissionType.surviveSeconds, 60, 'Superviviente', 'Sobrevive 60 segundos en una carrera', 150),
  (MissionType.useJump, 5, 'Saltarín', 'Salta 5 veces en una carrera', 50),
  (MissionType.useJump, 15, 'Acróbata', 'Salta 15 veces en una carrera', 100),
];

class MissionRepositoryImpl implements MissionRepository {
  final MissionLocalDatasource _datasource;
  final _rng = Random();

  MissionRepositoryImpl(this._datasource);

  @override
  Future<List<Mission>> getActiveMissions() async {
    final raw = _datasource.getRawMissions();
    if (raw == null || raw.isEmpty) return _generateAndSave();
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => Mission.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (_) {
      return _generateAndSave();
    }
  }

  @override
  Future<List<Mission>> advanceMissions(MissionRunData data) async {
    final missions = await getActiveMissions();
    final updated = missions.map((m) {
      if (m.isCompleted) return m;
      final gained = data.progressFor(m.type);
      final newProgress = (m.progress + gained).clamp(0, m.target);
      return m.copyWith(progress: newProgress);
    }).toList();
    await _save(updated);

    // Auto-refresh if all done
    if (updated.every((m) => m.isCompleted)) {
      return _generateAndSave();
    }
    return updated;
  }

  @override
  Future<List<Mission>> refreshMissions() => _generateAndSave();

  List<Mission> _generate() {
    final shuffled = List.of(_templates)..shuffle(_rng);
    final picked = <MissionType>{};
    final result = <Mission>[];
    for (final t in shuffled) {
      if (picked.contains(t.$1)) continue;
      picked.add(t.$1);
      result.add(Mission(
        id: '${t.$1.name}_${t.$2}_${DateTime.now().millisecondsSinceEpoch}',
        type: t.$1,
        title: t.$3,
        description: t.$4,
        target: t.$2,
        progress: 0,
        rewardCoins: t.$5,
      ));
      if (result.length == 3) break;
    }
    return result;
  }

  Future<List<Mission>> _generateAndSave() async {
    final missions = _generate();
    await _save(missions);
    return missions;
  }

  Future<void> _save(List<Mission> missions) async {
    final json = jsonEncode(missions.map((m) => m.toJson()).toList());
    await _datasource.saveRawMissions(json);
  }
}
