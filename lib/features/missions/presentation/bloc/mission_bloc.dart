import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/mission_repository.dart';
import 'mission_event.dart';
import 'mission_state.dart';

class MissionBloc extends Bloc<MissionEvent, MissionState> {
  final MissionRepository repository;

  MissionBloc({required this.repository}) : super(const MissionState()) {
    on<LoadMissions>(_onLoad);
    on<AdvanceMissionsEvent>(_onAdvance);
    on<RefreshMissionsEvent>(_onRefresh);
  }

  Future<void> _onLoad(LoadMissions _, Emitter<MissionState> emit) async {
    emit(state.copyWith(status: MissionStatus.loading));
    final missions = await repository.getActiveMissions();
    emit(state.copyWith(status: MissionStatus.ready, missions: missions));
  }

  Future<void> _onAdvance(
      AdvanceMissionsEvent event, Emitter<MissionState> emit) async {
    final before = state.missions;
    final after = await repository.advanceMissions(event.data);

    // Detect newly completed missions (were incomplete, now complete)
    final newly = after
        .where((m) => m.isCompleted &&
            before.any((b) => b.id == m.id && !b.isCompleted))
        .toList();

    emit(state.copyWith(
      missions: after,
      justCompleted: newly,
    ));
  }

  Future<void> _onRefresh(
      RefreshMissionsEvent _, Emitter<MissionState> emit) async {
    final missions = await repository.refreshMissions();
    emit(state.copyWith(missions: missions, justCompleted: const []));
  }
}
