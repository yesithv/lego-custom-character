import 'dart:async';
import 'dart:convert';

import '../domain/analytics_service.dart';
import '../domain/entities/analytics_event.dart';
import '../domain/entities/analytics_summary.dart';
import 'datasources/analytics_local_datasource.dart';
import 'models/analytics_event_model.dart';

/// Analítica **first-party** persistida en local (Hive).
///
/// No usa SDKs de terceros (requisito iOS Kids). Toda la escritura es
/// "dispara y olvida" y está envuelta en try/catch: la analítica nunca debe
/// tumbar el juego ni bloquear la UI.
class LocalAnalyticsService implements AnalyticsService {
  final AnalyticsLocalDatasource _ds;
  LocalAnalyticsService(this._ds);

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void startSession() {
    unawaited(() async {
      try {
        final now = DateTime.now();
        if (_ds.firstOpenMs == null) {
          await _ds.setFirstOpenMs(now.millisecondsSinceEpoch);
        }
        await _ds.setSessions(_ds.sessions + 1);
        await _markActiveDay(now);
        await _write(AnalyticsEvents.appOpen, null, now);
      } catch (_) {
        // La analítica nunca debe propagar errores.
      }
    }());
  }

  @override
  void track(String event, {Map<String, Object?>? params}) {
    unawaited(() async {
      try {
        final now = DateTime.now();
        await _markActiveDay(now);
        await _write(event, params, now);
      } catch (_) {}
    }());
  }

  Future<void> _write(
      String name, Map<String, Object?>? params, DateTime now) {
    return _ds.append(AnalyticsEventModel(
      name: name,
      tsMs: now.millisecondsSinceEpoch,
      paramsJson: (params == null || params.isEmpty) ? null : jsonEncode(params),
    ));
  }

  Future<void> _markActiveDay(DateTime now) async {
    final key = _dayKey(now);
    final days = _ds.activeDays;
    if (!days.contains(key)) {
      await _ds.setActiveDays([...days, key]);
    }
  }

  @override
  Future<AnalyticsSummary> getSummary() async {
    final events = _ds.events();
    final counts = <String, int>{};
    for (final e in events) {
      counts[e.name] = (counts[e.name] ?? 0) + 1;
    }

    final firstMs = _ds.firstOpenMs;
    final first =
        firstMs != null ? DateTime.fromMillisecondsSinceEpoch(firstMs) : null;
    final active = _ds.activeDays;

    DateTime? last;
    if (events.isNotEmpty) {
      final maxMs =
          events.map((e) => e.tsMs).reduce((a, b) => a > b ? a : b);
      last = DateTime.fromMillisecondsSinceEpoch(maxMs);
    }

    var retD1 = false;
    var retD7 = false;
    if (first != null) {
      retD1 = active.contains(_dayKey(first.add(const Duration(days: 1))));
      retD7 = active.contains(_dayKey(first.add(const Duration(days: 7))));
    }

    return AnalyticsSummary(
      totalEvents: events.length,
      sessions: _ds.sessions,
      eventCounts: counts,
      firstOpen: first,
      lastActive: last,
      activeDays: active.length,
      retainedD1: retD1,
      retainedD7: retD7,
    );
  }

  @override
  Future<List<AnalyticsEvent>> recentEvents({int limit = 50}) async {
    final models = _ds.events();
    models.sort((a, b) => b.tsMs.compareTo(a.tsMs));
    return models.take(limit).map((m) {
      Map<String, Object?> params = const {};
      final raw = m.paramsJson;
      if (raw != null) {
        try {
          params = (jsonDecode(raw) as Map).cast<String, Object?>();
        } catch (_) {}
      }
      return AnalyticsEvent(
        name: m.name,
        timestamp: DateTime.fromMillisecondsSinceEpoch(m.tsMs),
        params: params,
      );
    }).toList();
  }

  @override
  Future<void> clear() => _ds.clear();
}
