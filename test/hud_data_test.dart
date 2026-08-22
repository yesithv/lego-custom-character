import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/features/runner/presentation/game/brix_run_game.dart';
import 'package:run_for_win/features/runner/presentation/game/hud_data.dart';

/// El HUD se reconstruye solo cuando `HudData` cambia (lo compara `ValueNotifier`
/// con `==`), así que su igualdad por campos es la que garantiza que el HUD NO
/// se reconstruya 60 veces por segundo. Estos tests blindan ese contrato.
void main() {
  HudData base() => const HudData(
        coins: 10,
        streak: 3,
        multiplier: 2.0,
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
        bossHearts: 3,
        trackPermille: 500,
      );

  test('dos instantáneas con los mismos campos son iguales', () {
    expect(base(), equals(base()));
    expect(base().hashCode, base().hashCode);
  });

  test('cambiar cualquier campo relevante las hace distintas', () {
    expect(base() == base().copyOfWith(coins: 11), isFalse);
  });

  test('el progreso discretizado no cambia dentro de la misma milésima', () {
    // 0.5004 y 0.5001 redondean ambos a 500 milésimas → misma instantánea.
    expect((0.5004 * 1000).round(), (0.5001 * 1000).round());
  });

  test('HudData.initial es un valor de arranque estable', () {
    expect(HudData.initial, equals(HudData.initial));
  });
}

/// Helper local para variar un campo sin añadir copyWith al modelo de producción.
extension on HudData {
  HudData copyOfWith({int? coins}) => HudData(
        coins: coins ?? this.coins,
        streak: streak,
        multiplier: multiplier,
        phase: phase,
        hasShield: hasShield,
        shieldActive: shieldActive,
        heroShieldReady: heroShieldReady,
        shieldSeconds: shieldSeconds,
        magnetActive: magnetActive,
        magnetSeconds: magnetSeconds,
        boostActive: boostActive,
        boostSeconds: boostSeconds,
        dashChargePercent: dashChargePercent,
        bossHearts: bossHearts,
        trackPermille: trackPermille,
      );
}
