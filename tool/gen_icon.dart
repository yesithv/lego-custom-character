// Generador del icono de la app (Run For Win).
//
// Dibuja el icono por código —igual que el juego dibuja a los personajes— y
// exporta todos los tamaños que necesitan Android y la ficha de Google Play.
// No hay ningún PNG "fuente" que mantener: se edita este archivo y se vuelve a
// generar.
//
//   flutter test tool/gen_icon.dart
//
// (Se ejecuta con `flutter test` porque hace falta el rasterizador de Flutter
// para exportar PNG. Vive en `tool/` y no en `test/` a propósito, para que no
// forme parte de la batería de pruebas.)
//
// Salidas:
//   android/app/src/main/res/mipmap-*/ic_launcher.png            (icono clásico)
//   android/app/src/main/res/mipmap-*/ic_launcher_foreground.png (capa adaptativa)
//   docs/publicacion/icono-512.png                               (ficha de Play)
//   docs/publicacion/icono-preview.png                           (vista previa)
//
// Dos variantes (constante [kVariant], una línea para cambiar):
//
//   • [IconVariant.brick] (la que se publica): un bloque amarillo con estelas de
//     velocidad. Dice "juego de bloques + carrera" sin usar el elemento de
//     *trade dress* más delicado.
//   • [IconVariant.minifigHead]: cabeza de minifigura sonriente. Encaja mejor con
//     el arte del juego, pero una cabeza amarilla con stud es justo la seña de
//     identidad que `docs/publicacion/CHECKLIST-PUBLICACION.md` marca como riesgo
//     de propiedad intelectual, y el icono es la superficie más visible de la app.
//
// Legible a 48 px en las dos: una sola figura, mucho contraste y cero texto.

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Qué figura se dibuja en el icono.
enum IconVariant {
  /// Bloque amarillo con estelas. Menos riesgo de IP → es la que se publica.
  brick,

  /// Cabeza de minifigura sonriente. Más cercana al arte del juego.
  minifigHead,
}

/// Variante que se exporta a `android/` y a la ficha de la tienda.
const kVariant = IconVariant.brick;

// Paleta de marca (misma que el tema de la app).
const _brixYellow = Color(0xFFFFD700);
const _brixBlueTop = Color(0xFF0B4CA8);
const _brixBlueBottom = Color(0xFF05306B);
const _faceInk = Color(0xFF2B2000);

/// Fondo azul con patrón de puntos, como el Home del juego.
/// [inset] recorta el degradado a un cuadrado redondeado (icono clásico);
/// con `inset = 0` cubre todo el lienzo (capa de fondo del icono adaptativo).
void _paintBackground(Canvas canvas, double s, {required bool rounded}) {
  final rect = Rect.fromLTWH(0, 0, s, s);
  if (rounded) {
    canvas.save();
    canvas.clipRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(s * 0.22)));
  }
  canvas.drawRect(
    rect,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_brixBlueTop, _brixBlueBottom],
      ).createShader(rect),
  );
  // Puntos sutiles
  final dot = Paint()..color = Colors.white.withValues(alpha: 0.055);
  final step = s / 9;
  for (var y = step / 2; y < s; y += step) {
    for (var x = step / 2; x < s; x += step) {
      canvas.drawCircle(Offset(x, y), s * 0.014, dot);
    }
  }
  if (rounded) canvas.restore();
}

/// Estelas de velocidad a la izquierda de la figura. Se recortan al lienzo con
/// un margen, para que nunca queden cortadas contra el borde del icono.
void _paintSpeedStreaks(Canvas canvas, double s, Rect figure) {
  final streak = Paint()
    ..color = Colors.white.withValues(alpha: 0.72)
    ..strokeCap = StrokeCap.round;
  final margin = s * 0.10;
  final lengths = [0.20, 0.30, 0.16];
  for (var i = 0; i < 3; i++) {
    final y = figure.top + figure.height * (0.20 + i * 0.30);
    streak.strokeWidth = s * (0.032 - i * 0.005);
    final x0 = math.max(margin, figure.left - s * lengths[i]);
    final x1 = figure.left - s * 0.05;
    if (x1 <= x0) continue;
    canvas.drawLine(Offset(x0, y), Offset(x1, y), streak);
  }
}

/// Bloque Brix: ladrillo amarillo de 3 studs, con acabado de plástico.
void _paintBrick(Canvas canvas, double s, Rect body) {
  final studR = body.width * 0.115;
  final studY = body.top - studR * 0.55;
  for (final f in [0.22, 0.5, 0.78]) {
    final c = Offset(body.left + body.width * f, studY);
    final r = Rect.fromCircle(center: c, radius: studR);
    canvas.drawOval(
      Rect.fromCenter(
          center: c, width: studR * 2, height: studR * 1.55),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_lighten(_brixYellow, 0.14), _darken(_brixYellow, 0.06)],
        ).createShader(r),
    );
  }

  final rr = RRect.fromRectAndRadius(body, Radius.circular(body.height * 0.16));
  canvas.drawRRect(
    rr,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _lighten(_brixYellow, 0.12),
          _brixYellow,
          _darken(_brixYellow, 0.14),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(body),
  );
  canvas.drawRRect(
    rr,
    Paint()
      ..color = _darken(_brixYellow, 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.013,
  );
  // Reflejo de plástico brillante
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(body.left + body.width * 0.07,
          body.top + body.height * 0.12, body.width * 0.42, body.height * 0.20),
      Radius.circular(body.height * 0.10),
    ),
    Paint()..color = Colors.white.withValues(alpha: 0.30),
  );
}

/// Cabeza de minifigura: bloque amarillo brillante con stud arriba y cara.
void _paintHead(Canvas canvas, double s, Rect head) {
  // Stud (mini cilindro) asomando por la coronilla
  final studR = head.width * 0.17;
  final studC = Offset(head.center.dx, head.top - studR * 0.45);
  final studRect = Rect.fromCircle(center: studC, radius: studR);
  canvas.drawCircle(
    studC,
    studR,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        colors: [
          _lighten(_brixYellow, 0.16),
          _brixYellow,
          _darken(_brixYellow, 0.16),
        ],
      ).createShader(studRect),
  );

  // Bloque de la cabeza
  final rr = RRect.fromRectAndRadius(head, Radius.circular(head.width * 0.20));
  canvas.drawRRect(
    rr,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _lighten(_brixYellow, 0.10),
          _brixYellow,
          _darken(_brixYellow, 0.13),
        ],
        stops: const [0.0, 0.52, 1.0],
      ).createShader(head),
  );
  // Contorno tonal (nunca negro plano)
  canvas.drawRRect(
    rr,
    Paint()
      ..color = _darken(_brixYellow, 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.012,
  );
  // Brillo de plástico en la mejilla
  canvas.drawOval(
    Rect.fromLTWH(head.left + head.width * 0.10, head.top + head.height * 0.10,
        head.width * 0.24, head.height * 0.34),
    Paint()..color = Colors.white.withValues(alpha: 0.22),
  );

  // Cara: ojos con destello + sonrisa
  final eyeR = head.width * 0.085;
  final eyeY = head.top + head.height * 0.42;
  for (final dx in [-0.20, 0.20]) {
    final c = Offset(head.center.dx + head.width * dx, eyeY);
    canvas.drawCircle(c, eyeR, Paint()..color = _faceInk);
    canvas.drawCircle(
      Offset(c.dx - eyeR * 0.3, c.dy - eyeR * 0.32),
      eyeR * 0.32,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }
  final smile = Path()
    ..moveTo(head.center.dx - head.width * 0.20,
        head.top + head.height * 0.62)
    ..quadraticBezierTo(
      head.center.dx,
      head.top + head.height * 0.80,
      head.center.dx + head.width * 0.20,
      head.top + head.height * 0.62,
    );
  canvas.drawPath(
    smile,
    Paint()
      ..color = _faceInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.022
      ..strokeCap = StrokeCap.round,
  );
}

Color _lighten(Color c, double a) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness + a).clamp(0.0, 1.0)).toColor();
}

Color _darken(Color c, double a) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness - a).clamp(0.0, 1.0)).toColor();
}

/// Icono completo (fondo + figura). [rounded] recorta las esquinas.
class _IconPainter extends CustomPainter {
  final IconVariant variant;
  final bool withBackground;
  final bool rounded;

  /// Fracción del lienzo que ocupa la cabeza. En el icono adaptativo la figura
  /// tiene que caber en el 66 % central (zona segura), porque el launcher
  /// recorta los bordes con la forma que quiera.
  final double headScale;

  const _IconPainter({
    required this.variant,
    required this.withBackground,
    required this.rounded,
    required this.headScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    if (withBackground) _paintBackground(canvas, s, rounded: rounded);

    // Figura ligeramente a la derecha: deja aire a las estelas de velocidad.
    final side = s * headScale;
    final figure = switch (variant) {
      IconVariant.minifigHead => Rect.fromCenter(
          center: Offset(s * 0.56, s * 0.53),
          width: side,
          height: side * 0.94,
        ),
      IconVariant.brick => Rect.fromCenter(
          center: Offset(s * 0.56, s * 0.55),
          width: side * 1.20,
          height: side * 0.62,
        ),
    };

    // Inclinación leve: sensación de carrera
    canvas.save();
    canvas.translate(figure.center.dx, figure.center.dy);
    canvas.rotate(-0.06);
    canvas.translate(-figure.center.dx, -figure.center.dy);
    _paintSpeedStreaks(canvas, s, figure);
    switch (variant) {
      case IconVariant.minifigHead:
        _paintHead(canvas, s, figure);
      case IconVariant.brick:
        _paintBrick(canvas, s, figure);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<void> _writePng(
  WidgetTester tester,
  String path,
  int px, {
  required bool withBackground,
  required bool rounded,
  required double headScale,
}) async {
  const key = ValueKey('icon');
  tester.view.physicalSize = Size(px + 40, px + 40);
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: key,
          child: CustomPaint(
            size: Size(px.toDouble(), px.toDouble()),
            painter: _IconPainter(
              variant: kVariant,
              withBackground: withBackground,
              rounded: rounded,
              headScale: headScale,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  });
  // ignore: avoid_print
  print('  ✓ $path (${px}px)');
}

void main() {
  // Densidades de Android: el icono clásico mide 48 dp y la capa adaptativa
  // 108 dp; los píxeles salen de multiplicar por la densidad.
  const densities = <String, double>{
    'mdpi': 1.0,
    'hdpi': 1.5,
    'xhdpi': 2.0,
    'xxhdpi': 3.0,
    'xxxhdpi': 4.0,
  };
  const resDir = 'android/app/src/main/res';

  testWidgets('genera los iconos de la app', (tester) async {
    for (final entry in densities.entries) {
      final dir = '$resDir/mipmap-${entry.key}';
      // Icono clásico: 48 dp, figura grande, esquinas redondeadas.
      await _writePng(
        tester,
        '$dir/ic_launcher.png',
        (48 * entry.value).round(),
        withBackground: true,
        rounded: true,
        headScale: 0.46,
      );
      // Capa frontal del icono adaptativo: 108 dp, figura dentro del 66 %
      // central y fondo transparente (lo pone `ic_launcher_background`).
      await _writePng(
        tester,
        '$dir/ic_launcher_foreground.png',
        (108 * entry.value).round(),
        withBackground: false,
        rounded: false,
        headScale: 0.34,
      );
    }

    // Ficha de Google Play: PNG de 512×512 sin transparencia.
    await _writePng(
      tester,
      'docs/publicacion/icono-512.png',
      512,
      withBackground: true,
      rounded: true,
      headScale: 0.46,
    );

    // Vista previa grande para revisar el diseño.
    await _writePng(
      tester,
      'docs/publicacion/icono-preview.png',
      768,
      withBackground: true,
      rounded: true,
      headScale: 0.46,
    );

    expect(File('$resDir/mipmap-xxxhdpi/ic_launcher.png').existsSync(), isTrue);
    expect(math.min(1, 1), 1);
  });
}
