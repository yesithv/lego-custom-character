import 'package:hive/hive.dart';

part 'analytics_event_model.g.dart';

@HiveType(typeId: 5)
class AnalyticsEventModel extends HiveObject {
  @HiveField(0)
  String name;

  /// Momento del evento en epoch millis.
  @HiveField(1)
  int tsMs;

  /// Parámetros serializados como JSON (null si no hay).
  @HiveField(2)
  String? paramsJson;

  AnalyticsEventModel({
    required this.name,
    required this.tsMs,
    this.paramsJson,
  });
}
