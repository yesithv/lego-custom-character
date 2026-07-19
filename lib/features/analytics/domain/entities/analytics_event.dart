/// Un evento de analítica registrado (nombre + momento + parámetros).
class AnalyticsEvent {
  final String name;
  final DateTime timestamp;
  final Map<String, Object?> params;

  const AnalyticsEvent({
    required this.name,
    required this.timestamp,
    this.params = const {},
  });
}

/// Nombres de eventos del funnel. Centralizados para evitar erratas y para que
/// el panel de depuración y la instrumentación hablen el mismo idioma.
class AnalyticsEvents {
  const AnalyticsEvents._();

  static const appOpen = 'app_open';
  static const runStart = 'run_start';
  static const runVictory = 'run_victory';
  static const runDeath = 'run_death';
  static const rouletteSpin = 'roulette_spin';
  static const storeOpen = 'store_open';
  static const parentalGateShown = 'parental_gate_shown';
  static const parentalGatePassed = 'parental_gate_passed';
  static const purchaseAttempt = 'purchase_attempt';
  static const purchaseSuccess = 'purchase_success';
}
