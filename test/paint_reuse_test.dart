import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/core/services/audio_service.dart';
import 'package:run_for_win/features/runner/presentation/game/brix_run_game.dart';
import 'package:run_for_win/features/runner/presentation/game/components/background_component.dart';
import 'package:run_for_win/features/runner/presentation/game/components/scenery_component.dart';

import 'player_position_test.dart' show startGame;

/// El fondo se redibuja ENTERO en cada frame: cielo, catorce edificios con sus
/// ventanas y su remate, el suelo con su rejilla y sus raíles. Sus colores
/// salen de `WorldColors`, que no cambia mientras se juega, así que crear los
/// `Paint` dentro del `render` era tirar y rehacer las mismas cuarenta
/// instancias sesenta veces por segundo.
///
/// Esto no cuenta líneas de código: registra las llamadas reales al lienzo y
/// comprueba, **por identidad**, que el segundo frame reutiliza exactamente los
/// mismos objetos que el primero.

/// Lienzo que anota cada llamada que recibe. `noSuchMethod` intercepta toda la
/// superficie de `Canvas` sin tener que implementarla a mano.
class _RecordingCanvas implements Canvas {
  final List<Symbol> calls = [];
  final List<Paint> paints = [];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation.memberName);
    for (final arg in invocation.positionalArguments) {
      if (arg is Paint) paints.add(arg);
    }
    return null;
  }
}

/// Dibuja un frame de [component] y devuelve lo que se pidió al lienzo.
// ignore: library_private_types_in_public_api
_RecordingCanvas renderFrame(Component component) {
  final canvas = _RecordingCanvas();
  component.render(canvas);
  return canvas;
}

BackgroundComponent backgroundOf(BrixRunGame game) =>
    game.children.whereType<BackgroundComponent>().single;

void main() {
  setUpAll(() => AudioService.instance.muteAll = true);

  group('El fondo no crea Paint por frame', () {
    testWidgets('el segundo frame reutiliza los mismos objetos que el primero',
        (tester) async {
      final game = await startGame(tester);
      final bg = backgroundOf(game);

      final first = renderFrame(bg);
      // Avanza el mundo para que el fondo se desplace: no es el mismo dibujo,
      // pero debe pintarse con los mismos `Paint`.
      await tester.pump(const Duration(milliseconds: 200));
      final second = renderFrame(bg);

      expect(first.paints, isNotEmpty);
      final reused = second.paints.where(
        (p) => first.paints.any((q) => identical(p, q)),
      );
      expect(reused.length, second.paints.length,
          reason: 'todo Paint del segundo frame debe venir del primero');
    });

    testWidgets('el número de Paint distintos no crece con los frames',
        (tester) async {
      final game = await startGame(tester);
      final bg = backgroundOf(game);

      final seen = Set<Paint>.identity();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        seen.addAll(renderFrame(bg).paints);
      }

      // Diez frames de una pista que además se desplaza. Sin reutilización esto
      // serían cientos de instancias.
      expect(seen.length, lessThan(30),
          reason: 'se vieron ${seen.length} Paint distintos en 10 frames');
    });
  });

  group('Todas las pistas', () {
    // Cada mundo tiene su propio remate de tejado y su decoración de cielo, y
    // cada uno estrena camino de dibujo: se recorren todos para que ninguno se
    // quede con un `Paint` creado al vuelo o con una referencia rota.
    for (final world in const [
      'brix_city',
      'medieval',
      'galaxy',
      'jungle',
      'ocean',
      'tundra',
      'dark_city',
      'robot_city',
    ]) {
      testWidgets('$world dibuja y reutiliza sus Paint', (tester) async {
        final game = await startGame(tester, worldId: world);
        final bg = backgroundOf(game);

        final first = renderFrame(bg);
        await tester.pump(const Duration(milliseconds: 200));
        final second = renderFrame(bg);

        // El número de operaciones SÍ varía entre frames: el fondo se
        // desplaza, así que entran y salen edificios y líneas de rejilla. Lo
        // que no puede variar son los objetos con los que se pintan.
        expect(first.calls, isNotEmpty, reason: '$world no pintó nada');
        expect(second.paints, isNotEmpty);
        for (final p in second.paints) {
          expect(first.paints.any((q) => identical(p, q)), isTrue,
              reason: '$world creó un Paint nuevo en el segundo frame');
        }
      });
    }
  });

  group('El escenario tampoco', () {
    // Los adornos de los márgenes se dibujan una vez por elemento vivo (media
    // docena larga) y sus colores son constantes de código: ni dependen del
    // mundo ni del elemento, así que un solo `Paint` por color sirve para
    // todos. Los que sí varían —los neones que laten— quedan fuera del caché a
    // propósito, porque su clave cambiaría en cada frame.
    testWidgets('los adornos comparten sus Paint entre elementos y frames',
        (tester) async {
      final game = await startGame(tester, worldId: 'brix_city');
      await tester.pump(const Duration(seconds: 2)); // puebla los márgenes

      final scenery = game.children.whereType<SceneryComponent>().toList();
      expect(scenery.length, greaterThan(2), reason: 'debe haber adornos');

      final seen = Set<Paint>.identity();
      var uses = 0;
      for (var frame = 0; frame < 5; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        for (final s in scenery) {
          final c = renderFrame(s);
          seen.addAll(c.paints);
          uses += c.paints.length;
        }
      }

      expect(uses, greaterThan(30), reason: 'se dibujó poco para medir nada');
      expect(seen.length * 2, lessThan(uses),
          reason: 'se usaron $uses Paint pero solo ${seen.length} objetos: '
              'sin caché habría uno nuevo por uso');
    });
  });
}
