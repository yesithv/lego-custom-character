import 'package:equatable/equatable.dart';

import '../../domain/entities/mission.dart';

sealed class MissionEvent extends Equatable {
  const MissionEvent();
  @override
  List<Object?> get props => [];
}

class LoadMissions extends MissionEvent {
  const LoadMissions();
}

class AdvanceMissionsEvent extends MissionEvent {
  final MissionRunData data;
  const AdvanceMissionsEvent(this.data);
  @override
  List<Object?> get props => [data];
}

class RefreshMissionsEvent extends MissionEvent {
  const RefreshMissionsEvent();
}
