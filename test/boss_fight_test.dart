import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lego_custom_character/core/services/audio_service.dart';
import 'package:lego_custom_character/features/character_editor/domain/entities/character.dart';
import 'package:lego_custom_character/features/runner/domain/entities/boss_config.dart';
import 'package:lego_custom_character/features/runner/presentation/game/brix_run_game.dart';
import 'package:lego_custom_character/features/runner/presentation/game/components/boss_component.dart';

/// Monta el juego en un GameWidget para que el ticker de test lo pilote.
Future<BrixRunGame> startGame(
  WidgetTester tester, {
  String worldId = 'medieval',
  CharacterType type = CharacterType.neutral,
  int bossTriggerMeters = 3,
}) async {
  final game = BrixRunGame(
    appearance: const CharacterAppearance(),
    characterType: type,
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

/// Avanza el juego hasta que se cumpla [cond] (o venza [maxSeconds]).
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() cond, {
  double maxSeconds = 15,
}) async {
  var t = 0.0;
  while (!cond() && t < maxSeconds) {
    await tester.pump(const Duration(milliseconds: 50));
    t += 0.05;
  }
}

void main() {
  setUpAll(() {
    // Evita llamadas a canales de plataforma de audioplayers en tests
    AudioService.instance.muted = true;
  });

  testWidgets('la carrera empieza en fase running y sin jefe', (tester) async {
    final game = await startGame(tester);
    expect(game.phase, GamePhase.running);
    expect(game.children.whereType<BossComponent>(), isEmpty);
    expect(game.bossHearts, BrixRunGame.maxBossHearts);
  });

  testWidgets('al llegar a la meta aparece el jefe y comienza la pelea',
      (tester) async {
    final game = await startGame(tester);
    // A 220 px/s se llega a 3 m (300 px) en ~1.4 s
    await pumpUntil(tester, () => game.phase != GamePhase.running);
    expect(game.phase, GamePhase.bossIntro);
    await pumpUntil(
        tester, () => game.children.whereType<BossComponent>().isNotEmpty,
        maxSeconds: 1);
    expect(game.children.whereType<BossComponent>().length, 1);

    // La entrada dura ~2.3 s (profundidad 0.06 → 0.52 a 0.20/s)
    await pumpUntil(tester, () => game.phase == GamePhase.bossFight);
    expect(game.phase, GamePhase.bossFight);
  });

  testWidgets('durante la pelea el jefe lanza ataques', (tester) async {
    final game = await startGame(tester);
    await pumpUntil(tester, () => game.phase == GamePhase.bossFight);
    expect(game.phase, GamePhase.bossFight);
    await pumpUntil(tester,
        () => game.children.whereType<BossAttackComponent>().isNotEmpty,
        maxSeconds: 4);
    expect(game.children.whereType<BossAttackComponent>(), isNotEmpty);
  });

  testWidgets('5 esquives llenan la carga y embisten: el jefe pierde un corazón',
      (tester) async {
    final game = await startGame(tester);
    await pumpUntil(tester, () => game.phase == GamePhase.bossFight);
    expect(game.phase, GamePhase.bossFight);

    for (var i = 0; i < 4; i++) {
      game.onAttackDodged();
    }
    expect(game.dashCharge, closeTo(0.8, 0.001));
    expect(game.bossHearts, BrixRunGame.maxBossHearts);

    game.onAttackDodged();
    await tester.pump(const Duration(milliseconds: 50));
    expect(game.dashCharge, 0);
    expect(game.bossHearts, BrixRunGame.maxBossHearts - 1);
  });

  testWidgets('tres embestidas derrotan al jefe y dan la victoria con botín',
      (tester) async {
    final game = await startGame(tester);
    await pumpUntil(tester, () => game.phase == GamePhase.bossFight);
    expect(game.phase, GamePhase.bossFight);

    final coinsBefore = game.coins;
    for (var i = 0; i < 15; i++) {
      game.onAttackDodged();
    }
    expect(game.bossHearts, 0);
    expect(game.phase, GamePhase.bossDefeated);

    // La animación de derrota dura 1.5 s y luego llega la victoria
    await simulate(tester, 2);
    expect(game.phase, GamePhase.victory);
    expect(game.coins, coinsBefore + BrixRunGame.victoryCoinBonus);
    expect(game.bossBonusScore, greaterThan(0));
    expect(game.overlays.isActive('victory'), isTrue);
    // Deja que el Future.delayed de la pausa del motor se dispare
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('un ataque que golpea sin escudo termina la carrera',
      (tester) async {
    final game = await startGame(tester);
    await pumpUntil(tester, () => game.phase == GamePhase.bossFight);
    expect(game.phase, GamePhase.bossFight);

    // Proyectil en el carril del jugador justo en la ventana de impacto
    game.add(BossAttackComponent(
      kind: BossAttackKind.projectile,
      lane: 1,
      depth: 0.95,
    ));
    await simulate(tester, 0.3);
    expect(game.isAlive, isFalse);
    // Deja disparar el Future.delayed del game over antes de cerrar el test
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('el héroe absorbe el primer golpe del jefe con su escudo',
      (tester) async {
    final game = await startGame(tester, type: CharacterType.hero);
    await pumpUntil(tester, () => game.phase == GamePhase.bossFight);
    expect(game.phase, GamePhase.bossFight);
    expect(game.hasShield, isTrue);

    game.add(BossAttackComponent(
      kind: BossAttackKind.shockwave,
      depth: 0.95,
    ));
    await simulate(tester, 0.3);
    expect(game.isAlive, isTrue);
    expect(game.hasShield, isFalse);
  });

  testWidgets('restart limpia por completo el estado del jefe', (tester) async {
    final game = await startGame(tester);
    await pumpUntil(tester, () => game.phase == GamePhase.bossFight);
    expect(game.phase, GamePhase.bossFight);
    for (var i = 0; i < 15; i++) {
      game.onAttackDodged();
    }
    await simulate(tester, 2);
    expect(game.phase, GamePhase.victory);
    await tester.pump(const Duration(milliseconds: 500));

    game.restart();
    await tester.pump(const Duration(milliseconds: 50));
    expect(game.phase, GamePhase.running);
    expect(game.bossHearts, BrixRunGame.maxBossHearts);
    expect(game.dashCharge, 0);
    expect(game.bossBonusScore, 0);
    expect(game.children.whereType<BossComponent>(), isEmpty);
    expect(game.children.whereType<BossAttackComponent>(), isEmpty);
    expect(game.overlays.isActive('victory'), isFalse);
  });

  test('cada mundo tiene un jefe con nombre y config propios', () {
    final names = <String>{};
    for (final worldId in [
      'lego_city', 'medieval', 'galaxy', 'jungle',
      'dark_city', 'ocean', 'tundra', 'robot_city',
    ]) {
      final cfg = bossFor(worldId);
      names.add(cfg.name);
      final total =
          cfg.projectileWeight + cfg.shockwaveWeight + cfg.sweepWeight;
      expect(total, greaterThan(0), reason: 'pesos de $worldId');
      // El reparto de ataques cubre los tres tipos según el roll
      expect(cfg.attackForRoll(0.0), BossAttackKind.projectile);
      expect(cfg.attackForRoll(0.999), BossAttackKind.sweep);
    }
    expect(names.length, 8, reason: 'los 8 jefes tienen nombres únicos');
  });
}
