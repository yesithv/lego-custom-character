import 'brix_run_game.dart' show GamePhase;

/// Instantánea **discreta** del estado que pinta el HUD.
///
/// El juego la publica en un `ValueNotifier<HudData>` cada frame, pero como
/// `ValueNotifier` solo notifica cuando el valor **cambia** (usa `==`), el HUD
/// se reconstruye únicamente cuando alguno de estos campos cambia de verdad
/// (unas pocas veces por segundo) en lugar de 60 veces por segundo.
///
/// Por eso todos los campos son **discretos**: los tiempos de power-up se
/// guardan como segundos enteros (lo que muestra el dock), la carga de embestida
/// como porcentaje entero y el progreso de pista en milésimas. Un `double`
/// continuo (que cambia cada frame) haría que `==` fallara siempre y anularía
/// la optimización.
class HudData {
  final int coins;
  final int streak;
  final double multiplier;
  final GamePhase phase;

  final bool hasShield;
  final bool shieldActive;
  final bool heroShieldReady;
  final int shieldSeconds;

  final bool magnetActive;
  final int magnetSeconds;

  final bool boostActive;
  final int boostSeconds;

  final int dashChargePercent;
  final int bossHearts;

  /// Progreso por la pista en milésimas (0–1000). Discretizado para no notificar
  /// cada frame; el HUD lee `game.trackProgress` a resolución completa al pintar.
  final int trackPermille;

  const HudData({
    required this.coins,
    required this.streak,
    required this.multiplier,
    required this.phase,
    required this.hasShield,
    required this.shieldActive,
    required this.heroShieldReady,
    required this.shieldSeconds,
    required this.magnetActive,
    required this.magnetSeconds,
    required this.boostActive,
    required this.boostSeconds,
    required this.dashChargePercent,
    required this.bossHearts,
    required this.trackPermille,
  });

  static const HudData initial = HudData(
    coins: 0,
    streak: 0,
    multiplier: 1.0,
    phase: GamePhase.running,
    hasShield: false,
    shieldActive: false,
    heroShieldReady: false,
    shieldSeconds: 0,
    magnetActive: false,
    magnetSeconds: 0,
    boostActive: false,
    boostSeconds: 0,
    dashChargePercent: 0,
    bossHearts: 0,
    trackPermille: 0,
  );

  @override
  bool operator ==(Object other) =>
      other is HudData &&
      other.coins == coins &&
      other.streak == streak &&
      other.multiplier == multiplier &&
      other.phase == phase &&
      other.hasShield == hasShield &&
      other.shieldActive == shieldActive &&
      other.heroShieldReady == heroShieldReady &&
      other.shieldSeconds == shieldSeconds &&
      other.magnetActive == magnetActive &&
      other.magnetSeconds == magnetSeconds &&
      other.boostActive == boostActive &&
      other.boostSeconds == boostSeconds &&
      other.dashChargePercent == dashChargePercent &&
      other.bossHearts == bossHearts &&
      other.trackPermille == trackPermille;

  @override
  int get hashCode => Object.hash(
        coins,
        streak,
        multiplier,
        phase,
        hasShield,
        shieldActive,
        heroShieldReady,
        shieldSeconds,
        magnetActive,
        magnetSeconds,
        boostActive,
        boostSeconds,
        dashChargePercent,
        bossHearts,
        trackPermille,
      );
}
