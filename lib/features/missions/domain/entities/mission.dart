import 'package:equatable/equatable.dart';

enum MissionType {
  collectCoins,
  runMeters,
  evadeObstacles,
  surviveSeconds,
  useJump,
}

class Mission extends Equatable {
  final String id;
  final MissionType type;
  final String title;
  final String description;
  final int target;
  final int progress;
  final int rewardCoins;

  const Mission({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.target,
    required this.progress,
    required this.rewardCoins,
  });

  bool get isCompleted => progress >= target;
  double get progressRatio => (progress / target).clamp(0.0, 1.0);

  Mission copyWith({int? progress}) => Mission(
        id: id,
        type: type,
        title: title,
        description: description,
        target: target,
        progress: progress ?? this.progress,
        rewardCoins: rewardCoins,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'title': title,
        'description': description,
        'target': target,
        'progress': progress,
        'rewardCoins': rewardCoins,
      };

  factory Mission.fromJson(Map<String, dynamic> json) => Mission(
        id: json['id'] as String,
        type: MissionType.values[json['type'] as int],
        title: json['title'] as String,
        description: json['description'] as String,
        target: json['target'] as int,
        progress: json['progress'] as int,
        rewardCoins: json['rewardCoins'] as int,
      );

  @override
  List<Object?> get props => [id, type, target, progress];
}

class MissionRunData {
  final int coins;
  final int meters;
  final int evadedObstacles;
  final int seconds;
  final int jumps;

  const MissionRunData({
    required this.coins,
    required this.meters,
    required this.evadedObstacles,
    required this.seconds,
    required this.jumps,
  });

  int progressFor(MissionType type) => switch (type) {
        MissionType.collectCoins => coins,
        MissionType.runMeters => meters,
        MissionType.evadeObstacles => evadedObstacles,
        MissionType.surviveSeconds => seconds,
        MissionType.useJump => jumps,
      };
}
