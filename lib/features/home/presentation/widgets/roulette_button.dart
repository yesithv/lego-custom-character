import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Acceso a la ruleta diaria. Se dibuja como una rueda de premios (no un dado)
/// y comunica dos estados:
/// - [available]: rueda a color que da un giro corto cada pocos segundos, con
///   halo dorado latiendo y badge rojo.
/// - Ya girada: rueda apagada y estática, con badge de check verde; sigue
///   siendo tocable para revisar el premio del día.
///
/// Es puramente presentacional: quien lo usa decide de dónde sale [available].
class RouletteButton extends StatefulWidget {
  const RouletteButton({
    super.key,
    required this.available,
    required this.onTap,
  });

  final bool available;
  final VoidCallback onTap;

  /// Key del `CustomPaint` de la rueda, para poder localizarlo en tests.
  static const wheelKey = ValueKey('roulette-wheel');

  @override
  State<RouletteButton> createState() => _RouletteButtonState();
}

class _RouletteButtonState extends State<RouletteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Giro "teaser": la rueda descansa, arranca, frena y vuelve a reposo.
  /// Ocupa el primer 65% del ciclo; el resto es una pausa corta — con pausas
  /// largas el botón parece estático si lo miras en el momento equivocado.
  static const _spinCurve = Interval(0, 0.65, curve: Curves.easeInOutCubic);

  /// Vueltas enteras: la marca de premio vuelve a su sitio, así que el ciclo
  /// encadena sin salto. Dos vueltas en ~2.3s se siguen con la vista.
  static const _spinTurns = 2.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(RouletteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.available != widget.available) _syncAnimation();
  }

  /// Sin giro pendiente no hay nada que animar: el controller se detiene.
  void _syncAnimation() {
    if (widget.available) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.available;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // El halo late solo cuando hay giro disponible, a ritmo propio
            // (3 latidos por ciclo) para no quedar atado al frenado.
            final pulse = available
                ? 0.5 + 0.5 * math.sin(_controller.value * 6 * math.pi)
                : 0.0;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF042A5C).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                  if (available)
                    BoxShadow(
                      color: const Color(
                        0xFFFFC400,
                      ).withValues(alpha: 0.30 + 0.45 * pulse),
                      blurRadius: 10 + 10 * pulse,
                      spreadRadius: 1 + 2 * pulse,
                    ),
                ],
              ),
              child: child,
            );
          },
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => CustomPaint(
                      key: RouletteButton.wheelKey,
                      painter: RouletteWheelPainter(
                        // Estática cuando ya se giró: refuerza el "hecho".
                        rotation: available
                            ? _spinCurve.transform(_controller.value) *
                                _spinTurns *
                                2 *
                                math.pi
                            : 0.0,
                        active: available,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: available
              ? Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                )
              : Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E9E4F),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.check, size: 8, color: Colors.white),
                ),
        ),
      ],
    );
  }
}

/// Dibuja una ruleta de premios: sectores alternos, aro exterior, eje central
/// y la aguja superior. En estado inactivo usa una paleta apagada.
class RouletteWheelPainter extends CustomPainter {
  const RouletteWheelPainter({required this.rotation, required this.active});

  final double rotation;
  final bool active;

  static const _activeColors = [
    Color(0xFFE8402A),
    Color(0xFFFFC400),
    Color(0xFF0A4A9E),
    Color(0xFF2E9E4F),
  ];

  static const _mutedColors = [
    Color(0xFFBFC7D2),
    Color(0xFFDDE3EA),
    Color(0xFFAAB4C2),
    Color(0xFFCFD6DF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final wheelRadius = radius * 0.86; // deja aire para la aguja

    final colors = active ? _activeColors : _mutedColors;
    const sectors = 8;
    const sweep = 2 * math.pi / sectors;
    final rect = Rect.fromCircle(center: center, radius: wheelRadius);

    for (var i = 0; i < sectors; i++) {
      canvas.drawArc(
        rect,
        rotation + i * sweep - math.pi / 2,
        sweep,
        true,
        Paint()..color = colors[i % colors.length],
      );
    }

    // Marca de premio: rompe la simetría de la rueda. Sin ella el patrón de
    // color se repite cada 4 sectores y el giro es casi imperceptible — la
    // rueda parece la misma en cada fotograma.
    final markerAngle = rotation - math.pi / 2 + sweep / 2;
    final markerCenter = Offset(
      center.dx + math.cos(markerAngle) * wheelRadius * 0.55,
      center.dy + math.sin(markerAngle) * wheelRadius * 0.55,
    );
    canvas.drawCircle(
      markerCenter,
      radius * 0.15,
      Paint()
        ..color = active ? Colors.white : const Color(0xFFF2F5F8),
    );

    // Aro exterior.
    canvas.drawCircle(
      center,
      wheelRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.14
        ..color = active ? const Color(0xFF042A5C) : const Color(0xFF8B96A5),
    );

    // Eje central.
    canvas.drawCircle(center, radius * 0.18, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      radius * 0.18,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.07
        ..color = active ? const Color(0xFF042A5C) : const Color(0xFF8B96A5),
    );

    // Aguja: triángulo apuntando hacia el centro desde arriba.
    final pointer = Path()
      ..moveTo(center.dx - radius * 0.16, center.dy - radius)
      ..lineTo(center.dx + radius * 0.16, center.dy - radius)
      ..lineTo(center.dx, center.dy - wheelRadius * 0.62)
      ..close();
    canvas.drawPath(
      pointer,
      Paint()
        ..color = active ? const Color(0xFFFFC400) : const Color(0xFFB9C2CD),
    );
    canvas.drawPath(
      pointer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.06
        ..strokeJoin = StrokeJoin.round
        ..color = active ? const Color(0xFF042A5C) : const Color(0xFF8B96A5),
    );
  }

  @override
  bool shouldRepaint(RouletteWheelPainter old) =>
      old.rotation != rotation || old.active != active;
}
