import 'dart:ui' show Offset;

import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/features/runner/presentation/input/swipe_detector.dart';

/// Fija la política del gesto del corredor. El caso que da nombre a todo esto
/// es el primero: la acción debe salir MIENTRAS el dedo se mueve, porque
/// esperar a levantarlo se percibía como si el juego se congelara.
void main() {
  group('El swipe se resuelve durante el arrastre', () {
    test('cruzar el umbral dispara la acción sin levantar el dedo', () {
      final d = SwipeDetector();
      d.start(const Offset(100, 300));

      // Aún por debajo del umbral: nada todavía.
      expect(d.update(const Offset(115, 300)), isNull);

      // Al cruzarlo, la acción sale en ese mismo movimiento.
      expect(d.update(const Offset(130, 300)), SwipeAction.right);
    });

    test('al levantar el dedo no se repite lo ya disparado', () {
      final d = SwipeDetector();
      d.start(const Offset(100, 300));
      expect(d.update(const Offset(140, 300)), SwipeAction.right);

      // El dedo se levanta con velocidad: no debe producir un SEGUNDO carril.
      expect(d.end(const Offset(900, 0)), isNull);
    });

    test('un arrastre lento y largo se registra igual (velocidad final ≈ 0)',
        () {
      final d = SwipeDetector();
      d.start(const Offset(100, 300));
      SwipeAction? fired;
      // Movimiento en pasos de 4 px, como el de un dedo que arrastra despacio.
      for (var x = 104.0; x <= 140 && fired == null; x += 4) {
        fired = d.update(Offset(x, 300));
      }
      expect(fired, SwipeAction.right);
      expect(d.end(Offset.zero), isNull);
    });
  });

  group('Encadenar movimientos en un mismo arrastre', () {
    test('seguir arrastrando dispara un segundo carril', () {
      final d = SwipeDetector();
      d.start(const Offset(100, 300));
      expect(d.update(const Offset(130, 300)), SwipeAction.right);
      // Desde el nuevo ancla (130) hacen falta `repeatDistance` px más.
      expect(d.update(const Offset(160, 300)), isNull);
      expect(d.update(const Offset(180, 300)), SwipeAction.right);
    });

    test('la deriva del dedo tras un swipe NO cuenta como otro', () {
      final d = SwipeDetector();
      d.start(const Offset(100, 300));
      expect(d.update(const Offset(130, 300)), SwipeAction.right);
      // 30 px más: supera el umbral inicial (24) pero no el de repetición (44).
      expect(d.update(const Offset(160, 300)), isNull);
    });

    test('cambiar de sentido a mitad de arrastre mueve al otro lado', () {
      final d = SwipeDetector();
      d.start(const Offset(100, 300));
      expect(d.update(const Offset(130, 300)), SwipeAction.right);
      expect(d.update(const Offset(80, 300)), SwipeAction.left);
    });
  });

  group('Flick corto: red de seguridad por velocidad', () {
    test('un flick que no recorre el umbral se resuelve al levantar', () {
      final d = SwipeDetector();
      d.start(const Offset(100, 300));
      expect(d.update(const Offset(110, 300)), isNull);
      expect(d.end(const Offset(-800, 0)), SwipeAction.left);
    });

    test('soltar el dedo quieto no dispara nada', () {
      final d = SwipeDetector();
      d.start(const Offset(100, 300));
      d.update(const Offset(105, 300));
      expect(d.end(Offset.zero), isNull);
    });
  });

  group('Eje dominante', () {
    test('vertical hacia arriba salta; hacia abajo se agacha', () {
      final d = SwipeDetector();
      d.start(const Offset(200, 400));
      expect(d.update(const Offset(200, 360)), SwipeAction.up);

      d.start(const Offset(200, 400));
      expect(d.update(const Offset(200, 440)), SwipeAction.down);
    });

    test('en diagonal manda el eje con más recorrido', () {
      final d = SwipeDetector();
      d.start(const Offset(200, 400));
      // 40 px a la derecha y 30 hacia arriba: gana la horizontal.
      expect(d.update(const Offset(240, 370)), SwipeAction.right);
    });
  });

  group('Ciclo de vida del gesto', () {
    test('update sin start no produce nada', () {
      expect(SwipeDetector().update(const Offset(500, 500)), isNull);
    });

    test('cancel corta el gesto en curso', () {
      final d = SwipeDetector();
      d.start(const Offset(100, 300));
      d.cancel();
      expect(d.isTracking, isFalse);
      expect(d.update(const Offset(300, 300)), isNull);
    });

    test('end deja el detector listo para el siguiente gesto', () {
      final d = SwipeDetector();
      d.start(const Offset(100, 300));
      d.update(const Offset(140, 300));
      d.end(Offset.zero);

      expect(d.isTracking, isFalse);
      expect(d.hasFired, isFalse);
      d.start(const Offset(100, 300));
      expect(d.update(const Offset(140, 300)), SwipeAction.right);
    });
  });
}
