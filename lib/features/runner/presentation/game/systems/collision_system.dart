part of '../brix_run_game.dart';

/// Detección de colisiones manual por profundidad (obstáculos, monedas y
/// power-ups), extraída de [BrixRunGame]. Cada objeto se resuelve una sola vez,
/// cuando cruza el plano del jugador (depth ≈ 1.0). Colaborador real en un
/// `part` de la misma librería; opera sobre el estado del juego vía [g].
class CollisionSystem {
  final BrixRunGame g;
  CollisionSystem(this.g);

  void check() {
    const hitMin = 0.87;
    const hitMax = 1.11;
    const pastPlayer = 1.16;
    final playerLane = g._player.currentLane;

    // Cada obstáculo se resuelve UNA sola vez, en el momento en que cruza el
    // plano del jugador (depth ≈ 1.0, donde el personaje está de verdad).
    for (final obs in g.activeObstacles) {
      if (obs.collided || obs.evaded) continue;
      if (obs.depth < BrixRunGame._collisionDepth) continue; // aún no llega

      // Obstáculos del tutorial: nunca son letales (solo enseñan).
      if (obs.tutorial) {
        obs.evaded = true;
        continue;
      }

      // Otro carril: pasa de largo, cuenta como esquivado.
      if (obs.lane != playerLane) {
        obs.evaded = true;
        g.evadedObstacle();
        continue;
      }

      // Mismo carril: ¿lo está librando el jugador en este instante?
      // Las barreras colgantes (overhead) NO se pueden saltar: solo agacharse.
      final jumpingClear = g._player.isJumping &&
          g._player.jumpProgress > 0.10 &&
          g._player.jumpProgress < 0.90 &&
          obs.type != ObstacleType.overhead;
      // Deslizarse pasa por debajo de las barreras (bajas o colgantes).
      final slidingClear = g._player.isSliding &&
          (obs.type == ObstacleType.barrier ||
              obs.type == ObstacleType.overhead);
      // El turbo arrasa con cualquier obstáculo sin recibir daño.
      if (jumpingClear || slidingClear || g.boostActive) {
        obs.evaded = true;
        if (g.boostActive) obs.collided = true; // efecto de arrasado
        g.evadedObstacle();
        continue;
      }

      obs.collided = true;
      g.hitObstacle();
      return;
    }

    for (final coin in g.activeCoins) {
      // Las monedas atraídas por el imán vuelan solas y se recogen al llegar.
      if (coin.collected || coin.magnetized) continue;
      // Magnet grabs adjacent lanes too
      final inRange = coin.lane == playerLane ||
          (g.magnetActive && (coin.lane - playerLane).abs() == 1);
      if (inRange && coin.depth >= hitMin && coin.depth <= hitMax) {
        coin.collected = true;
        coin.removeFromParent();
        g.collectCoin();
      } else if (coin.depth >= pastPlayer) {
        coin.removeFromParent();
      }
    }

    for (final pu in g.activePowerups) {
      if (pu.collected) continue;
      if (pu.lane == playerLane && pu.depth >= hitMin && pu.depth <= hitMax) {
        pu.collected = true;
        pu.removeFromParent();
        g.activatePowerup(pu.type);
      } else if (pu.depth >= pastPlayer) {
        pu.removeFromParent();
      }
    }
  }
}
