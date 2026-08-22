part of '../brix_run_game.dart';

/// Dirige la secuencia guiada del tutorial (4 pasos, uno por control),
/// extraída de [BrixRunGame]. Colaborador real en un `part` de la misma
/// librería: el estado del tutorial sigue en el juego y se accede por [g].
class TutorialDirector {
  final BrixRunGame g;
  TutorialDirector(this.g);

  /// Conduce la secuencia: lanza cada paso, espera a que sus obstáculos salgan
  /// de escena y pasa al siguiente hasta terminar.
  void advance(double dt) {
    if (!g._tutorialStepSpawned) {
      // Cuenta atrás antes de lanzar el paso actual (más larga la primera vez).
      g._tutorialGap += dt;
      final delay = g._tutorialStep == 0
          ? BrixRunGame._tutorialStartDelay
          : BrixRunGame._tutorialStepGap;
      if (g._tutorialGap >= delay) {
        g._tutorialGap = 0;
        _spawnStep(g._tutorialStep);
        g._tutorialStepSpawned = true;
      }
      return;
    }

    // Paso lanzado: avanzar cuando todos sus obstáculos ya cruzaron al corredor.
    if (g._tutorialObstacles.every((o) => !o.isMounted)) {
      g._tutorialHint?.removeFromParent();
      g._tutorialHint = null;
      g._tutorialObstacles.clear();
      g._tutorialStepSpawned = false;
      g._tutorialStep++;
      if (g._tutorialStep >= BrixRunGame._tutorialStepCount) {
        g._tutorialActive = false; // se reanuda la carrera normal
      }
    }
  }

  /// Lanza los obstáculos y la flecha de un paso. Cada paso **fuerza** su acción:
  /// - 0: muros en 1 y 2, hueco a la izquierda → mover ← (1→0).
  /// - 1: muros en 0 y 2, hueco en el centro → mover → (0→1).
  /// - 2: bloques de suelo en los 3 carriles (no se agachan) → saltar ↑.
  /// - 3: barreras colgantes en los 3 carriles (no se saltan) → agacharse ↓.
  void _spawnStep(int step) {
    // Un "muro" (bloque + colgante en el mismo carril) obliga a cambiar de carril.
    void wall(int lane) {
      _addObstacle(lane, ObstacleType.block);
      _addObstacle(lane, ObstacleType.overhead);
    }

    final HintDirection dir;
    switch (step) {
      case 0:
        wall(1);
        wall(2);
        dir = HintDirection.left;
      case 1:
        wall(0);
        wall(2);
        dir = HintDirection.right;
      case 2:
        for (var l = 0; l < 3; l++) {
          _addObstacle(l, ObstacleType.block);
        }
        dir = HintDirection.up;
      default:
        for (var l = 0; l < 3; l++) {
          _addObstacle(l, ObstacleType.overhead);
        }
        dir = HintDirection.down;
    }

    g._tutorialHint = TutorialHintComponent(direction: dir);
    g.add(g._tutorialHint!);
  }

  void _addObstacle(int lane, ObstacleType type) {
    final obs = ObstacleComponent(lane: lane, type: type, tutorial: true);
    g._tutorialObstacles.add(obs);
    g.add(obs);
  }

  void reset() {
    g._tutorialActive = g.showTutorial;
    g._tutorialStep = 0;
    g._tutorialStepSpawned = false;
    g._tutorialGap = 0;
    g._tutorialObstacles.clear();
    g._tutorialHint?.removeFromParent();
    g._tutorialHint = null;
  }
}
