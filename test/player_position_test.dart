import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/core/services/audio_service.dart';
import 'package:run_for_win/features/character_editor/domain/entities/character.dart';
import 'package:run_for_win/features/runner/presentation/game/brix_run_game.dart';
import 'package:run_for_win/features/runner/presentation/game/components/obstacle_component.dart';

/// Monta el juego en un GameWidget para que el ticker de test lo pilote.
/// [bossTriggerMeters] alto por defecto para que el jefe NO aparezca durante
/// las pruebas de posición/colisión del corredor.
Future<BrixRunGame> startGame(
  WidgetTester tester, {
  String worldId = 'brix_city',
  int bossTriggerMeters = 100000,
}) async {
  final game = BrixRunGame(
    appearance: const CharacterAppearance(),
    characterType: CharacterType.neutral,
    worldId: worldId,
    bossTriggerMeters: bossTriggerMeters,
  );
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: GameWidget<BrixRunGame>(
        game: game,
        overlayBuilderMap: {
          'hud': (_, __) => const SizedBox(),
          'gameOver': (_, __) => const SizedBox(),
          'victory': (_, __) => const SizedBox(),
          'continue': (_, __) => const SizedBox(),
        },
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  return game;
}

/// Simula [seconds] de juego en pasos de 50 ms.
Future<void> simulate(WidgetTester tester, double seconds) async {
  final steps = (seconds / 0.05).ceil();
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(() {
    // Evita llamadas a canales de plataforma de audioplayers en tests.
    AudioService.instance.muteAll = true;
  });

  group('Posición del corredor en la pista', () {
    testWidgets(
        'el corredor se sitúa bien abajo: entre el horizonte y el borde inferior',
        (tester) async {
      final game = await startGame(tester);

      // Debe quedar por debajo del centro (más abajo que antes) pero sin salirse
      // de la pantalla, para dejar más pista visible por delante.
      expect(game.playerBaseY, greaterThan(game.size.y * 0.5));
      expect(game.playerBaseY, lessThan(game.size.y));
      expect(game.playerBaseY, greaterThan(game.horizonY));
    });

    testWidgets(
        'INVARIANTE: el plano de colisión (depth 1.0) coincide con la altura '
        'del corredor en los 3 carriles', (tester) async {
      final game = await startGame(tester);

      // La colisión se decide en depth == 1.0. Si perspectivePos(*, 1.0).y no
      // fuese exactamente playerBaseY, los obstáculos golpearían por encima o
      // por debajo del corredor. Este invariante garantiza que —para CUALQUIER
      // valor de playerBaseY— el golpe ocurre justo donde está el personaje.
      for (var lane = 0; lane < 3; lane++) {
        expect(
          game.perspectivePos(lane, 1.0).y,
          closeTo(game.playerBaseY, 0.0001),
          reason: 'carril $lane',
        );
      }
    });

    testWidgets('la posición del corredor es la misma en todas las pistas',
        (tester) async {
      final worlds = ['brix_city', 'medieval', 'galaxy', 'jungle', 'ocean'];
      final bases = <double>[];
      for (final w in worlds) {
        final game = await startGame(tester, worldId: w);
        bases.add(game.playerBaseY / game.size.y);
      }
      // Todas las pistas comparten la misma fracción de altura.
      for (final b in bases) {
        expect(b, closeTo(bases.first, 0.0001));
      }
    });
  });

  group('Colisión de obstáculos en la nueva posición', () {
    testWidgets('un obstáculo en el carril del jugador lo golpea (sin esquivar)',
        (tester) async {
      final game = await startGame(tester);
      // Jugador en el carril central (1) por defecto.
      game.add(ObstacleComponent(
        lane: game.playerLane,
        type: ObstacleType.block,
        initialDepth: 0.9,
      ));
      // El obstáculo cruza el plano del corredor (depth 1.0) en ~0.24 s.
      await simulate(tester, 0.4);

      expect(game.awaitingContinue, isTrue,
          reason: 'un golpe mortal ofrece continuar');
    });

    testWidgets('saltar a tiempo libra un obstáculo de suelo', (tester) async {
      final game = await startGame(tester);
      game.add(ObstacleComponent(
        lane: game.playerLane,
        type: ObstacleType.block,
        initialDepth: 0.9,
      ));
      game.onSwipeUp(); // saltar
      await simulate(tester, 0.4);

      expect(game.awaitingContinue, isFalse, reason: 'el salto lo libra');
      expect(game.isAlive, isTrue);
      expect(game.obstacleStreak, greaterThan(0),
          reason: 'un esquive suma a la racha');
    });

    testWidgets('agacharse libra una barrera baja', (tester) async {
      final game = await startGame(tester);
      game.add(ObstacleComponent(
        lane: game.playerLane,
        type: ObstacleType.barrier,
        initialDepth: 0.9,
      ));
      game.onSwipeDown(); // agacharse
      await simulate(tester, 0.4);

      expect(game.awaitingContinue, isFalse);
      expect(game.isAlive, isTrue);
      expect(game.obstacleStreak, greaterThan(0));
    });

    testWidgets('un obstáculo en otro carril se esquiva sin golpe',
        (tester) async {
      final game = await startGame(tester);
      // Jugador en el carril 1; obstáculo en el 0.
      game.add(ObstacleComponent(
        lane: 0,
        type: ObstacleType.block,
        initialDepth: 0.9,
      ));
      await simulate(tester, 0.4);

      expect(game.awaitingContinue, isFalse);
      expect(game.isAlive, isTrue);
      expect(game.obstacleStreak, greaterThan(0));
    });
  });
}
