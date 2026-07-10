import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lego_custom_character/features/runner/domain/entities/boss_config.dart';
import 'package:lego_custom_character/features/runner/presentation/game/components/boss_painters.dart';

const _worlds = [
  'lego_city', 'medieval', 'galaxy', 'jungle',
  'dark_city', 'ocean', 'tundra', 'robot_city',
];

class _BossPainter extends CustomPainter {
  final String worldId;
  final int enrage;
  const _BossPainter(this.worldId, {this.enrage = 0});

  @override
  void paint(Canvas canvas, Size size) =>
      paintBoss(canvas, size, worldId, animT: 0.3, enrage: enrage);

  @override
  bool shouldRepaint(_BossPainter old) =>
      old.worldId != worldId || old.enrage != enrage;
}

class _AttackPainter extends CustomPainter {
  final String worldId;
  final BossAttackKind kind;
  const _AttackPainter(this.worldId, this.kind);

  @override
  void paint(Canvas canvas, Size size) =>
      paintBossAttack(canvas, size, kind, worldId, animT: 0.3);

  @override
  bool shouldRepaint(_AttackPainter old) =>
      old.worldId != worldId || old.kind != kind;
}

void main() {
  const boundaryKey = ValueKey('boss-boundary');

  Future<Uint8List> render(WidgetTester tester, CustomPainter painter,
      {Size size = const Size(120, 130)}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: boundaryKey,
          child: Center(
            child: CustomPaint(size: size, painter: painter),
          ),
        ),
      ),
    );
    await tester.pump();
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(boundaryKey));
    late Uint8List bytes;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData();
      bytes = data!.buffer.asUint8List();
      image.dispose();
    });
    return bytes;
  }

  testWidgets('cada mundo tiene un jefe visualmente distinto', (tester) async {
    final renders = <String, Uint8List>{};
    for (final world in _worlds) {
      renders[world] = await render(tester, _BossPainter(world));
    }
    for (var i = 0; i < _worlds.length; i++) {
      for (var j = i + 1; j < _worlds.length; j++) {
        expect(
          listEquals(renders[_worlds[i]], renders[_worlds[j]]),
          isFalse,
          reason:
              'Los jefes de ${_worlds[i]} y ${_worlds[j]} se ven idénticos',
        );
      }
    }
  });

  testWidgets('el jefe cambia visualmente al enfurecerse', (tester) async {
    for (final world in _worlds) {
      final calm = await render(tester, _BossPainter(world));
      final furious = await render(tester, _BossPainter(world, enrage: 2));
      expect(
        listEquals(calm, furious),
        isFalse,
        reason: 'El jefe de $world no muestra su furia',
      );
    }
  });

  testWidgets('los 3 tipos de ataque se distinguen dentro de cada mundo',
      (tester) async {
    for (final world in _worlds) {
      final renders = <BossAttackKind, Uint8List>{};
      for (final kind in BossAttackKind.values) {
        renders[kind] = await render(tester, _AttackPainter(world, kind),
            size: const Size(160, 48));
      }
      for (var i = 0; i < BossAttackKind.values.length; i++) {
        for (var j = i + 1; j < BossAttackKind.values.length; j++) {
          final a = BossAttackKind.values[i];
          final b = BossAttackKind.values[j];
          expect(
            listEquals(renders[a], renders[b]),
            isFalse,
            reason: 'En $world, los ataques $a y $b se ven idénticos',
          );
        }
      }
    }
  });

  testWidgets('el proyectil de cada mundo es temático (distinto entre mundos)',
      (tester) async {
    final renders = <String, Uint8List>{};
    for (final world in _worlds) {
      renders[world] = await render(
          tester, _AttackPainter(world, BossAttackKind.projectile),
          size: const Size(60, 60));
    }
    for (var i = 0; i < _worlds.length; i++) {
      for (var j = i + 1; j < _worlds.length; j++) {
        expect(
          listEquals(renders[_worlds[i]], renders[_worlds[j]]),
          isFalse,
          reason:
              'Proyectiles de ${_worlds[i]} y ${_worlds[j]} idénticos',
        );
      }
    }
  });
}
