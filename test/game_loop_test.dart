import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/core/services/audio_service.dart';
import 'package:run_for_win/features/character_editor/domain/entities/character.dart';
import 'package:run_for_win/features/runner/presentation/game/brix_run_game.dart';
import 'package:run_for_win/features/runner/presentation/game/components/powerup_component.dart';

/// Monta el juego en un GameWidget (igual que boss_fight_test) para que el
/// jugador y los componentes existan antes de invocar métodos del juego.
Future<BrixRunGame> startGame(
  WidgetTester tester, {
  CharacterType type = CharacterType.neutral,
  double coinMultiplier = 1.0,
}) async {
  final game = BrixRunGame(
    appearance: const CharacterAppearance(),
    characterType: type,
    worldId: 'brix_city',
    coinMultiplier: coinMultiplier,
    bossTriggerMeters: 100000, // el jefe no aparece durante estos tests
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

void main() {
  setUpAll(() => AudioService.instance.muteAll = true);

  group('Zonas de dificultad (por metros)', () {
    // currentZone/_zoneSpeedBonus solo dependen de `meters`, sin montar el juego.
    BrixRunGame game() => BrixRunGame(
          appearance: const CharacterAppearance(),
          characterType: CharacterType.neutral,
          worldId: 'brix_city',
          bossTriggerMeters: 100000,
        );

    test('inicio < 200 m', () {
      final g = game()..meters = 0;
      expect(g.currentZone, RunnerZone.inicio);
    });
    test('núcleo entre 200 y 600 m', () {
      final g = game()..meters = 350;
      expect(g.currentZone, RunnerZone.nucleo);
    });
    test('caos a partir de 600 m', () {
      final g = game()..meters = 700;
      expect(g.currentZone, RunnerZone.caos);
    });
  });

  group('Multiplicador VIP de monedas (acumulador fraccionario)', () {
    testWidgets('x1.5 no da saltos raros: 2 recogidas = 3 monedas',
        (tester) async {
      final g = await startGame(tester, coinMultiplier: 1.5);
      g.collectCoin();
      g.collectCoin();
      expect(g.coins, 3);
    });

    testWidgets('x1.5 tras 4 recogidas = 6 monedas', (tester) async {
      final g = await startGame(tester, coinMultiplier: 1.5);
      for (var i = 0; i < 4; i++) {
        g.collectCoin();
      }
      expect(g.coins, 6);
    });

    testWidgets('el villano recoge el doble por moneda', (tester) async {
      final g = await startGame(tester, type: CharacterType.villain);
      g.collectCoin();
      expect(g.coins, 2);
    });
  });

  group('Multiplicador por racha de esquives', () {
    testWidgets('sube a x2/x3/x5 en los umbrales 10/25/50', (tester) async {
      final g = await startGame(tester);
      for (var i = 0; i < 9; i++) {
        g.evadedObstacle();
      }
      expect(g.multiplier, 1.0, reason: '9 esquives siguen en x1');
      g.evadedObstacle(); // 10
      expect(g.multiplier, 2.0);
      for (var i = 0; i < 15; i++) {
        g.evadedObstacle();
      } // 25
      expect(g.multiplier, 3.0);
      for (var i = 0; i < 25; i++) {
        g.evadedObstacle();
      } // 50
      expect(g.multiplier, 5.0);
      expect(g.maxObstacleStreak, 50);
    });
  });

  group('Activación de power-ups', () {
    testWidgets('escudo, imán y turbo se activan con su tiempo', (tester) async {
      final g = await startGame(tester);

      g.activatePowerup(PowerupType.shield);
      expect(g.shieldPowerupActive, isTrue);
      expect(g.hasShield, isTrue);
      expect(g.shieldTimeLeft, greaterThan(0));

      g.activatePowerup(PowerupType.magnet);
      expect(g.magnetActive, isTrue);
      expect(g.magnetTimeLeft, greaterThan(0));

      g.activatePowerup(PowerupType.boost);
      expect(g.boostActive, isTrue);
      expect(g.boostTimeLeft, greaterThan(0));
    });
  });

  group('Escudo innato del héroe', () {
    testWidgets('el héroe empieza con escudo listo', (tester) async {
      final g = await startGame(tester, type: CharacterType.hero);
      expect(g.heroShieldReady, isTrue);
      expect(g.hasShield, isTrue);
    });
  });
}
