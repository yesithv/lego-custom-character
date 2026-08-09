import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/core/services/audio_service.dart';
import 'package:run_for_win/features/character_editor/domain/entities/character.dart';
import 'package:run_for_win/features/runner/presentation/game/brix_run_game.dart';
import 'package:run_for_win/features/runner/presentation/game/components/obstacle_component.dart';

/// Monta el juego con el overlay de continuación registrado y (opcional) un
/// callback de fin de carrera para comprobar el flujo de revive/Game Over.
Future<BrixRunGame> startGame(
  WidgetTester tester, {
  void Function(int coins)? onRunComplete,
}) async {
  final game = BrixRunGame(
    appearance: const CharacterAppearance(),
    characterType: CharacterType.neutral, // sin escudo innato: el golpe es mortal
    worldId: 'medieval',
    bossTriggerMeters: 500, // meta lejana para no disparar al jefe en el test
    onRunComplete: onRunComplete,
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

Future<void> simulate(WidgetTester tester, double seconds) async {
  final steps = (seconds / 0.05).ceil();
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(() {
    AudioService.instance.muteAll = true;
  });

  testWidgets('un golpe mortal ofrece continuar en vez de terminar la carrera',
      (tester) async {
    final game = await startGame(tester);
    await simulate(tester, 1.0); // acumula algo de progreso

    game.hitObstacle();
    await tester.pump();

    expect(game.awaitingContinue, isTrue,
        reason: 'Tras el golpe se espera la decisión de continuar.');
    expect(game.isAlive, isTrue,
        reason: 'La carrera aún no ha terminado: puede reanudarse.');
    expect(game.continuesUsed, 0,
        reason: 'Todavía no se ha pagado ninguna continuación.');
    expect(game.paused, isTrue, reason: 'El motor queda pausado en la oferta.');
  });

  testWidgets('continueRun retoma la carrera sin resetear el progreso',
      (tester) async {
    final game = await startGame(tester);
    await simulate(tester, 1.5);

    game.hitObstacle();
    await tester.pump();
    final metersBefore = game.meters;
    final scoreBefore = game.score;
    final speedBefore = game.speed;

    game.continueRun();
    await tester.pump();

    expect(game.isAlive, isTrue);
    expect(game.awaitingContinue, isFalse);
    expect(game.continuesUsed, 1, reason: 'Se contabiliza la continuación.');
    expect(game.paused, isFalse, reason: 'El motor se reanuda.');
    // El progreso NO se reinicia (a diferencia de restart()).
    expect(game.meters, greaterThanOrEqualTo(metersBefore));
    expect(game.score, greaterThanOrEqualTo(scoreBefore));
    expect(game.speed, speedBefore);
    // No quedan obstáculos que maten de inmediato y hay invulnerabilidad breve.
    expect(game.children.whereType<ObstacleComponent>(), isEmpty);
    expect(game.hasShield, isTrue,
        reason: 'Se concede un escudo breve al revivir.');
  });

  testWidgets('declineContinue termina la carrera y va al Game Over real',
      (tester) async {
    var completedCoins = -1;
    final game = await startGame(tester, onRunComplete: (c) => completedCoins = c);
    await simulate(tester, 1.0);

    game.hitObstacle();
    await tester.pump();
    game.declineContinue();
    await tester.pump();

    expect(game.awaitingContinue, isFalse);
    expect(game.isAlive, isFalse, reason: 'El rechazo sí termina la carrera.');

    // El Game Over contabiliza la carrera tras un breve retardo.
    await simulate(tester, 0.7);
    expect(completedCoins, isNot(-1),
        reason: 'onRunComplete debe dispararse una vez al terminar.');
  });

  testWidgets('el revive dentro de la pelea conserva los corazones del jefe',
      (tester) async {
    final game = await startGame(tester);
    // Simula estar en plena pelea con daño ya hecho al jefe.
    game.phase = GamePhase.bossFight;
    game.bossHearts = 1;

    game.hitObstacle();
    await tester.pump();
    game.continueRun();
    await tester.pump();

    expect(game.phase, GamePhase.bossFight,
        reason: 'continueRun no cambia de fase (restart sí lo haría).');
    expect(game.bossHearts, 1,
        reason: 'Los corazones del jefe no se restauran al revivir.');
  });
}
