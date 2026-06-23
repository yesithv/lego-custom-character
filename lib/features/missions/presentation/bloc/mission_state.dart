import 'package:equatable/equatable.dart';

import '../../domain/entities/mission.dart';

enum MissionStatus { initial, loading, ready }

class MissionState extends Equatable {
  final MissionStatus status;
  final List<Mission> missions;
  final List<Mission> justCompleted;

  const MissionState({
    this.status = MissionStatus.initial,
    this.missions = const [],
    this.justCompleted = const [],
  });

  MissionState copyWith({
    MissionStatus? status,
    List<Mission>? missions,
    List<Mission>? justCompleted,
  }) =>
      MissionState(
        status: status ?? this.status,
        missions: missions ?? this.missions,
        justCompleted: justCompleted ?? this.justCompleted,
      );

  @override
  List<Object?> get props => [status, missions, justCompleted];
}
