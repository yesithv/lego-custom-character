import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../brix_run_game.dart';

/// Dirección que enseña una flecha del tutorial.
enum HintDirection { left, right, up, down }

/// Flecha animada que enseña un control durante el tutorial guiado.
///
/// Sigue el patrón manual del resto de efectos del juego (nada de
/// `OpacityEffect`/`MoveEffect` de Flame): la animación se calcula con un
/// acumulador `dt`. Cada ciclo la flecha **aparece, se desliza en su dirección y
/// se desvanece** (el gesto de swipe), en bucle, junto al corredor. La quita el
/// juego cuando avanza de paso; mientras tanto sigue al jugador.
class TutorialHintComponent extends PositionComponent
    with HasGameReference<BrixRunGame> {
  final HintDirection direction;
  double _t = 0;

  static const double _cycle = 1.15; // duración de un ciclo (s)
  static const double _drift = 34.0; // cuánto se desliza la flecha (px)
  static const double _offset = 78.0; // separación respecto al corredor (px)

  TutorialHintComponent({required this.direction}) : super(priority: 400);

  @override
  void update(double dt) {
    _t += dt;
    // Ancla la flecha al corredor para que lo acompañe al cambiar de carril.
    position = game.playerCenter;
  }

  Offset get _dirUnit => switch (direction) {
        HintDirection.left => const Offset(-1, 0),
        HintDirection.right => const Offset(1, 0),
        HintDirection.up => const Offset(0, -1),
        HintDirection.down => const Offset(0, 1),
      };

  @override
  void render(Canvas canvas) {
    final unit = _dirUnit;
    // Base: separada del corredor en la dirección indicada (arriba para saltar,
    // al lado para los carriles, sobre el pecho para agacharse).
    final baseX = unit.dx * _offset;
    final baseY = direction == HintDirection.down
        ? -_offset * 0.35
        : unit.dy * _offset - 24;

    // Dos flechas escalonadas para dar sensación de deslizamiento.
    for (var i = 0; i < 2; i++) {
      final phase = ((_t / _cycle) + i * 0.35) % 1.0;
      final alpha = sin(phase * pi).clamp(0.0, 1.0); // fade-in y fade-out
      if (alpha <= 0.01) continue;
      final dx = baseX + unit.dx * _drift * phase;
      final dy = baseY + unit.dy * _drift * phase;
      _drawArrow(canvas, Offset(dx, dy), alpha);
    }
  }

  void _drawArrow(Canvas canvas, Offset center, double alpha) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(switch (direction) {
      HintDirection.right => 0.0,
      HintDirection.down => pi / 2,
      HintDirection.left => pi,
      HintDirection.up => -pi / 2,
    });

    // Flecha apuntando a +X (se rota arriba según la dirección).
    const s = 26.0; // tamaño
    final head = Path()
      ..moveTo(s, 0)
      ..lineTo(s * 0.1, -s * 0.72)
      ..lineTo(s * 0.1, -s * 0.30)
      ..lineTo(-s * 0.85, -s * 0.30)
      ..lineTo(-s * 0.85, s * 0.30)
      ..lineTo(s * 0.1, s * 0.30)
      ..lineTo(s * 0.1, s * 0.72)
      ..close();

    // Halo/sombra para que resalte sobre cualquier mundo.
    canvas.drawPath(
      head,
      Paint()
        ..color = Colors.black.withValues(alpha: alpha * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeJoin = StrokeJoin.round,
    );
    // Relleno amarillo brillante.
    canvas.drawPath(
      head,
      Paint()..color = const Color(0xFFFFD54F).withValues(alpha: alpha),
    );
    canvas.drawPath(
      head,
      Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }
}
