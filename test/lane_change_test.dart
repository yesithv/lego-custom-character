import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/core/services/audio_service.dart';

import 'player_position_test.dart' show startGame;

/// Garantías del desplazamiento entre carriles. Antes era un suavizado
/// exponencial (`x += (destino - x) * k * dt`) que dependía de la tasa de
/// refresco y nunca terminaba de llegar; ahora es un tween de duración fija.
void main() {
  setUpAll(() {
    AudioService.instance.muteAll = true;
  });

  /// Avanza el juego [seconds] en pasos de [stepMs] ms, para poder comparar el
  /// mismo movimiento a distintas tasas de refresco.
  Future<void> run(WidgetTester tester, double seconds, int stepMs) async {
    final steps = (seconds * 1000 / stepMs).ceil();
    for (var i = 0; i < steps; i++) {
      await tester.pump(Duration(milliseconds: stepMs));
    }
  }

  group('El corredor llega al carril', () {
    testWidgets('tras el tiempo de cambio está EXACTAMENTE sobre el carril',
        (tester) async {
      final game = await startGame(tester);
      game.onSwipeRight();
      // 0.13 s de tween; 0.25 s da margen de sobra sin llegar a otro evento.
      await run(tester, 0.25, 16);

      expect(game.playerLane, 2);
      expect(game.playerX, closeTo(game.laneX(2), 0.01),
          reason: 'el tween debe aterrizar en el carril, no acercarse');
    });

    testWidgets('el movimiento arranca en el primer frame', (tester) async {
      final game = await startGame(tester);
      final before = game.playerX;
      game.onSwipeRight();
      await tester.pump(const Duration(milliseconds: 16));

      expect(game.playerX, greaterThan(before + 1),
          reason: 'un solo frame ya debe mover al corredor de forma visible');
    });
  });

  group('Independencia de la tasa de refresco', () {
    testWidgets('a 30 y a 120 fps el corredor acaba en el mismo sitio',
        (tester) async {
      final slow = await startGame(tester);
      slow.onSwipeRight();
      await run(tester, 0.25, 33); // ~30 fps
      final slowX = slow.playerX - slow.laneX(1);

      final fast = await startGame(tester);
      fast.onSwipeRight();
      await run(tester, 0.25, 8); // ~120 fps
      final fastX = fast.playerX - fast.laneX(1);

      expect(slowX, closeTo(fastX, 0.5),
          reason: 'el desplazamiento no puede depender del frame rate');
    });

    testWidgets('a media animación el avance es el mismo a 30 y a 120 fps',
        (tester) async {
      // El caso duro: comparar EN VUELO, donde el exponencial divergía más.
      final slow = await startGame(tester);
      slow.onSwipeRight();
      await run(tester, 0.064, 8);
      final slowProgress =
          (slow.playerX - slow.laneX(1)) / (slow.laneX(2) - slow.laneX(1));

      final fast = await startGame(tester);
      fast.onSwipeRight();
      await run(tester, 0.064, 32);
      final fastProgress =
          (fast.playerX - fast.laneX(1)) / (fast.laneX(2) - fast.laneX(1));

      expect(slowProgress, closeTo(fastProgress, 0.05));
    });
  });

  group('Encadenar carriles', () {
    testWidgets('dos cambios seguidos no reinician desde el centro',
        (tester) async {
      final game = await startGame(tester);
      game.onSwipeRight();
      await tester.pump(const Duration(milliseconds: 60)); // a mitad de camino
      final mid = game.playerX;
      expect(mid, greaterThan(game.laneX(1)));

      game.onSwipeRight(); // encadena al carril 2 desde donde está
      await tester.pump(const Duration(milliseconds: 16));

      expect(game.playerX, greaterThan(mid),
          reason: 'el segundo tramo sale de la posición actual, sin retroceder');
    });

    testWidgets('llega al carril final tras encadenar', (tester) async {
      final game = await startGame(tester);
      game.onSwipeLeft();
      await tester.pump(const Duration(milliseconds: 50));
      game.onSwipeRight();
      game.onSwipeRight();
      await run(tester, 0.3, 16);

      expect(game.playerLane, 2);
      expect(game.playerX, closeTo(game.laneX(2), 0.01));
    });
  });

  group('Bordes de la pista', () {
    testWidgets('en el carril extremo el movimiento se rechaza',
        (tester) async {
      final game = await startGame(tester);
      expect(game.onSwipeRight(), isTrue, reason: 'del centro al 2 sí se puede');
      expect(game.onSwipeRight(), isFalse, reason: 'del 2 no hay a dónde ir');
      expect(game.playerLane, 2);
    });

    testWidgets('rechazar no interrumpe el tween en curso', (tester) async {
      final game = await startGame(tester);
      game.onSwipeRight();
      await tester.pump(const Duration(milliseconds: 40));
      game.onSwipeRight(); // rechazado: ya va al carril 2
      await run(tester, 0.25, 16);

      expect(game.playerX, closeTo(game.laneX(2), 0.01));
    });
  });

  group('Carriles sin asignaciones por frame', () {
    testWidgets('laneX coincide con laneXPositions en los 3 carriles',
        (tester) async {
      final game = await startGame(tester);
      for (var lane = 0; lane < 3; lane++) {
        expect(game.laneX(lane), closeTo(game.laneXPositions[lane], 0.0001),
            reason: 'carril $lane');
      }
    });
  });
}
