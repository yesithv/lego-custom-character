part of '../brix_run_game.dart';

/// Fábrica de spawnables del juego (obstáculos, monedas, power-ups y
/// escenografía), extraída de [BrixRunGame]. La **cadencia** (cuándo generar)
/// sigue en el bucle `update` del juego; este sistema encapsula el **qué** se
/// genera y cómo. Vive en un `part` de la misma librería, así que usa el RNG y
/// el estado del juego a través de [g].
class SpawnSystem {
  final BrixRunGame g;
  SpawnSystem(this.g);

  void obstacle() {
    final lane = g._rng.nextInt(3);
    final roll = g._rng.nextDouble();
    final type = roll < 0.20
        ? ObstacleType.barrier
        : roll < 0.35
            ? ObstacleType.spike
            : ObstacleType.block;
    g.add(ObstacleComponent(lane: lane, type: type));

    // Caos zone: 20% chance of a second obstacle in a different lane
    if (g.currentZone == RunnerZone.caos && g._rng.nextDouble() < 0.20) {
      final otherLane = (lane + 1 + g._rng.nextInt(2)) % 3;
      final t2 =
          g._rng.nextDouble() < 0.3 ? ObstacleType.barrier : ObstacleType.block;
      g.add(ObstacleComponent(lane: otherLane, type: t2));
    }
  }

  void coin() {
    g.add(CoinComponent(lane: g._rng.nextInt(3)));
  }

  void powerup() {
    final type = PowerupType.values[g._rng.nextInt(PowerupType.values.length)];
    g.add(PowerupComponent(lane: g._rng.nextInt(3), type: type));
  }

  void scenery({double startDepth = 0.0}) {
    g.add(SceneryComponent(
      side: g._rng.nextBool() ? -1 : 1,
      variant: g._rng.nextInt(3),
      lateral: 2.0 + g._rng.nextDouble() * 1.1,
      startDepth: startDepth,
    ));
  }

  // Pre-populate both sides of the track so the world isn't empty on start.
  void seedScenery() {
    for (double d = 0.12; d <= 1.0; d += 0.16) {
      scenery(startDepth: d);
      if (g._rng.nextDouble() < 0.6) {
        scenery(startDepth: (d + 0.08).clamp(0.0, 1.0));
      }
    }
  }
}
