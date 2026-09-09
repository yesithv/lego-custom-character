import 'dart:ui';

/// Resplandores baratos para lo que se dibuja en cada frame.
///
/// Lo usan tanto los obstáculos de la pista —una vez por objeto vivo y por
/// frame— como las animaciones de recompensa, así que se escribe con dos
/// reglas:
///
/// 1. **Nada de `MaskFilter.blur`.** Un desenfoque obliga a la GPU a resolver
///    el objeto en una superficie aparte y filtrarla; con varios objetos en
///    pantalla eso son varios pasos de render por frame y se nota como caídas
///    de fotogramas en los móviles modestos, que son el público de este juego.
///    Un halo se aproxima igual de bien con dos o tres trazos concéntricos de
///    opacidad decreciente, que la GPU dibuja como cualquier otra forma.
/// 2. **Ningún `Paint` nuevo por frame.** Los `Paint` de aquí se reutilizan;
///    cada función fija TODOS los campos de los que depende, para que no se
///    filtre estado de un uso al siguiente.

/// Capas del halo, de fuera adentro: (ancho del trazo, opacidad relativa).
///
/// Tres capas bastan para que el degradado se lea como un resplandor; con dos
/// se ve el escalón y con cuatro ya no se distingue la diferencia.
const _glowLayers = <(double, double)>[
  (7.0, 0.16),
  (4.5, 0.28),
  (2.0, 0.45),
];

final _glowPaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round;

/// Dibuja un resplandor alrededor de [path], en sustitución de rellenarlo con
/// un desenfoque. [strength] (0–1) modula la intensidad, para auras que laten.
void drawGlowPath(Canvas canvas, Path path, Color color, {double strength = 1}) {
  if (strength <= 0) return;
  for (final (width, alpha) in _glowLayers) {
    _glowPaint
      ..color = color.withValues(alpha: alpha * strength)
      ..strokeWidth = width;
    canvas.drawPath(path, _glowPaint);
  }
}

final _glowDotPaint = Paint()..style = PaintingStyle.fill;

/// Dibuja un punto luminoso de radio [radius] en [center]: un núcleo sólido
/// rodeado de capas cada vez más tenues. Sustituye a un círculo desenfocado.
void drawGlowDot(Canvas canvas, Offset center, double radius, Color color,
    {double strength = 1}) {
  if (strength <= 0) return;
  for (final (spread, alpha) in _glowLayers) {
    _glowDotPaint.color = color.withValues(alpha: alpha * strength);
    canvas.drawCircle(center, radius + spread, _glowDotPaint);
  }
  _glowDotPaint.color = color;
  canvas.drawCircle(center, radius, _glowDotPaint);
}
