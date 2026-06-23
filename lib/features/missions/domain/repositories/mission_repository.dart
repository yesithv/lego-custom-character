import '../entities/mission.dart';

abstract class MissionRepository {
  Future<List<Mission>> getActiveMissions();
  Future<List<Mission>> advanceMissions(MissionRunData data);
  Future<List<Mission>> refreshMissions();
}
