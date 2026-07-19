import 'analytics_event.dart';

/// Resumen agregado del funnel, calculado a partir de los eventos locales.
///
/// ⚠️ **Solo por dispositivo.** Sin backend, estas cifras miden este
/// dispositivo (útil para QA e instrumentación). Para métricas de negocio
/// agregadas hará falta enviar los eventos a un *sink* remoto propio.
class AnalyticsSummary {
  final int totalEvents;
  final int sessions;
  final Map<String, int> eventCounts;
  final DateTime? firstOpen;
  final DateTime? lastActive;

  /// Nº de días naturales distintos con actividad.
  final int activeDays;

  /// Hubo actividad el día natural siguiente al primer uso.
  final bool retainedD1;

  /// Hubo actividad el 7.º día natural tras el primer uso.
  final bool retainedD7;

  const AnalyticsSummary({
    required this.totalEvents,
    required this.sessions,
    required this.eventCounts,
    required this.firstOpen,
    required this.lastActive,
    required this.activeDays,
    required this.retainedD1,
    required this.retainedD7,
  });

  int _c(String name) => eventCounts[name] ?? 0;

  int get runs => _c(AnalyticsEvents.runVictory) + _c(AnalyticsEvents.runDeath);
  int get victories => _c(AnalyticsEvents.runVictory);
  int get deaths => _c(AnalyticsEvents.runDeath);
  int get storeOpens => _c(AnalyticsEvents.storeOpen);
  int get purchases => _c(AnalyticsEvents.purchaseSuccess);

  /// Porcentaje de carreras que acaban en victoria (0–1), o null si no hay.
  double? get victoryRate => runs == 0 ? null : victories / runs;

  /// Compras / aperturas de tienda (0–1), o null si no hay aperturas.
  double? get purchaseConversion =>
      storeOpens == 0 ? null : purchases / storeOpens;
}
