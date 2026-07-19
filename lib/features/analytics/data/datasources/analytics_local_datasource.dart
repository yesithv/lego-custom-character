import 'package:hive/hive.dart';

import '../models/analytics_event_model.dart';

/// Acceso local a la analítica: un log de eventos (append-only) y una caja de
/// metadatos (primer uso, sesiones, días activos).
abstract class AnalyticsLocalDatasource {
  Future<void> append(AnalyticsEventModel event);
  List<AnalyticsEventModel> events();

  int? get firstOpenMs;
  Future<void> setFirstOpenMs(int ms);

  int get sessions;
  Future<void> setSessions(int value);

  List<String> get activeDays;
  Future<void> setActiveDays(List<String> days);

  Future<void> clear();
}

class AnalyticsLocalDatasourceImpl implements AnalyticsLocalDatasource {
  final Box<AnalyticsEventModel> _events;
  final Box<dynamic> _meta;

  AnalyticsLocalDatasourceImpl({
    required Box<AnalyticsEventModel> events,
    required Box<dynamic> meta,
  })  : _events = events,
        _meta = meta;

  static const _kFirstOpen = 'firstOpenMs';
  static const _kSessions = 'sessions';
  static const _kActiveDays = 'activeDays';

  @override
  Future<void> append(AnalyticsEventModel event) => _events.add(event);

  @override
  List<AnalyticsEventModel> events() => _events.values.toList();

  @override
  int? get firstOpenMs => _meta.get(_kFirstOpen) as int?;

  @override
  Future<void> setFirstOpenMs(int ms) => _meta.put(_kFirstOpen, ms);

  @override
  int get sessions => (_meta.get(_kSessions) as int?) ?? 0;

  @override
  Future<void> setSessions(int value) => _meta.put(_kSessions, value);

  @override
  List<String> get activeDays =>
      ((_meta.get(_kActiveDays) as List?)?.cast<String>()) ?? const [];

  @override
  Future<void> setActiveDays(List<String> days) =>
      _meta.put(_kActiveDays, days);

  @override
  Future<void> clear() async {
    await _events.clear();
    await _meta.clear();
  }
}
