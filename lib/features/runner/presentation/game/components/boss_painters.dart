import 'dart:math';

import 'package:flutter/material.dart';

import '../../../domain/entities/boss_config.dart';

/// Pintores puros de los jefes y sus ataques. Funciones standalone (sin
/// dependencia de Flame) para que la vista previa del juego y los tests
/// puedan renderizarlas directamente.

/// Dibuja el jefe del mundo [worldId] ocupando [size], de frente al jugador.
/// [animT] anima alas/tentáculos/luces; [enrage] (0–2) añade aura de furia;
/// [hitFlash] (0–1) superpone un destello blanco al recibir una embestida.
void paintBoss(
  Canvas canvas,
  Size size,
  String worldId, {
  double animT = 0,
  int enrage = 0,
  double hitFlash = 0,
}) {
  final cfg = bossFor(worldId);

  // Aura de furia detrás del cuerpo
  if (enrage > 0) {
    final aura = Paint()
      ..color = Colors.red.withValues(
          alpha: (0.12 + 0.10 * enrage) * (0.8 + 0.2 * sin(animT * 6)));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * (1.1 + 0.08 * enrage),
        height: size.height * (1.1 + 0.08 * enrage),
      ),
      aura,
    );
  }

  switch (worldId) {
    case 'medieval':
      _paintDragon(canvas, size, cfg, animT, enrage);
    case 'galaxy':
      _paintOverlord(canvas, size, cfg, animT, enrage);
    case 'jungle':
      _paintGorilla(canvas, size, cfg, animT, enrage);
    case 'dark_city':
      _paintShadow(canvas, size, cfg, animT, enrage);
    case 'ocean':
      _paintKraken(canvas, size, cfg, animT, enrage);
    case 'tundra':
      _paintYeti(canvas, size, cfg, animT, enrage);
    case 'robot_city':
      _paintMegaBot(canvas, size, cfg, animT, enrage);
    default:
      _paintForeman(canvas, size, cfg, animT, enrage);
  }

  if (hitFlash > 0) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.white.withValues(alpha: hitFlash.clamp(0.0, 0.8)),
    );
  }
}

// Ojos furiosos compartidos: círculos con cejas en V; crecen con [enrage].
void _angryEyes(Canvas canvas, Offset left, Offset right, double r,
    Color color, int enrage) {
  final eye = Paint()..color = color;
  final er = r * (1.0 + enrage * 0.18);
  canvas.drawCircle(left, er, eye);
  canvas.drawCircle(right, er, eye);
  final brow = Paint()
    ..color = Colors.black87
    ..strokeWidth = er * 0.55
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  canvas.drawLine(Offset(left.dx - er, left.dy - er * 1.6),
      Offset(left.dx + er, left.dy - er * 0.7), brow);
  canvas.drawLine(Offset(right.dx + er, right.dy - er * 1.6),
      Offset(right.dx - er, right.dy - er * 0.7), brow);
}

void _rrect(Canvas canvas, Rect rect, Color color, double radius) {
  canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()..color = color);
}

Color _darker(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}

Color _lighter(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}

// ── lego_city: Capataz Demoledor ────────────────────────────────────────────

void _paintForeman(
    Canvas canvas, Size size, BossConfig cfg, double t, int enrage) {
  final w = size.width;
  final h = size.height;
  const skin = Color(0xFFFFDBAC);

  // Bola de demolición colgando de una cadena (lado derecho)
  final swing = sin(t * 2.0) * w * 0.03;
  final chain = Paint()
    ..color = Colors.grey.shade700
    ..strokeWidth = w * 0.02;
  canvas.drawLine(Offset(w * 0.88, h * 0.38),
      Offset(w * 0.92 + swing, h * 0.72), chain);
  canvas.drawCircle(Offset(w * 0.92 + swing, h * 0.80), w * 0.11,
      Paint()..color = Colors.grey.shade800);
  canvas.drawCircle(Offset(w * 0.89 + swing, h * 0.77), w * 0.03,
      Paint()..color = Colors.white.withValues(alpha: 0.35));

  // Piernas
  _rrect(canvas, Rect.fromLTWH(w * 0.30, h * 0.72, w * 0.16, h * 0.24),
      Colors.blueGrey.shade800, 5);
  _rrect(canvas, Rect.fromLTWH(w * 0.54, h * 0.72, w * 0.16, h * 0.24),
      Colors.blueGrey.shade800, 5);

  // Torso: chaleco naranja con franjas reflectantes
  _rrect(canvas, Rect.fromLTWH(w * 0.22, h * 0.36, w * 0.56, h * 0.38),
      cfg.primary, 8);
  final stripe = Paint()..color = cfg.secondary;
  canvas.drawRect(Rect.fromLTWH(w * 0.30, h * 0.36, w * 0.07, h * 0.38), stripe);
  canvas.drawRect(Rect.fromLTWH(w * 0.63, h * 0.36, w * 0.07, h * 0.38), stripe);

  // Brazos
  _rrect(canvas, Rect.fromLTWH(w * 0.10, h * 0.38, w * 0.12, h * 0.28), skin, 6);
  _rrect(canvas, Rect.fromLTWH(w * 0.78, h * 0.38, w * 0.12, h * 0.28), skin, 6);

  // Cabeza
  _rrect(canvas, Rect.fromLTWH(w * 0.30, h * 0.10, w * 0.40, h * 0.26), skin, 8);
  _angryEyes(canvas, Offset(w * 0.41, h * 0.21), Offset(w * 0.59, h * 0.21),
      w * 0.035, Colors.black87, enrage);
  // Ceño fruncido
  final frown = Path()
    ..moveTo(w * 0.42, h * 0.31)
    ..quadraticBezierTo(w * 0.50, h * 0.27, w * 0.58, h * 0.31);
  canvas.drawPath(
      frown,
      Paint()
        ..color = Colors.black87
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round);

  // Casco de obra amarillo
  _rrect(canvas, Rect.fromLTWH(w * 0.26, h * 0.09, w * 0.48, h * 0.04),
      cfg.secondary, 4);
  canvas.drawArc(
      Rect.fromLTWH(w * 0.30, h * 0.005, w * 0.40, h * 0.19),
      pi, pi, true, Paint()..color = cfg.secondary);
}

// ── medieval: Dragón Oscuro ─────────────────────────────────────────────────

void _paintDragon(
    Canvas canvas, Size size, BossConfig cfg, double t, int enrage) {
  final w = size.width;
  final h = size.height;
  final flap = sin(t * 3.5) * h * 0.05;

  // Alas (detrás del cuerpo)
  final wing = Paint()..color = _darker(cfg.primary, 0.08);
  final leftWing = Path()
    ..moveTo(w * 0.32, h * 0.42)
    ..lineTo(w * 0.02, h * 0.16 + flap)
    ..lineTo(w * 0.10, h * 0.44 + flap * 0.5)
    ..lineTo(w * 0.05, h * 0.62)
    ..close();
  final rightWing = Path()
    ..moveTo(w * 0.68, h * 0.42)
    ..lineTo(w * 0.98, h * 0.16 + flap)
    ..lineTo(w * 0.90, h * 0.44 + flap * 0.5)
    ..lineTo(w * 0.95, h * 0.62)
    ..close();
  canvas.drawPath(leftWing, wing);
  canvas.drawPath(rightWing, wing);

  // Cola con púa (lado izquierdo)
  final tail = Path()
    ..moveTo(w * 0.35, h * 0.85)
    ..quadraticBezierTo(w * 0.08, h * 0.95, w * 0.06, h * 0.72)
    ..lineTo(w * 0.14, h * 0.78)
    ..quadraticBezierTo(w * 0.22, h * 0.90, w * 0.40, h * 0.78)
    ..close();
  canvas.drawPath(tail, Paint()..color = cfg.primary);

  // Cuerpo
  _rrect(canvas, Rect.fromLTWH(w * 0.26, h * 0.40, w * 0.48, h * 0.50),
      cfg.primary, 16);
  // Placas del vientre
  final belly = Paint()..color = _lighter(cfg.primary, 0.16);
  for (var i = 0; i < 4; i++) {
    _rrect(
        canvas,
        Rect.fromLTWH(w * 0.36, h * (0.52 + i * 0.095), w * 0.28, h * 0.06),
        belly.color,
        6);
  }

  // Cabeza con hocico
  _rrect(canvas, Rect.fromLTWH(w * 0.30, h * 0.10, w * 0.40, h * 0.24),
      cfg.primary, 10);
  _rrect(canvas, Rect.fromLTWH(w * 0.36, h * 0.26, w * 0.28, h * 0.12),
      _lighter(cfg.primary, 0.10), 6);
  // Fosas nasales + humo
  final nostril = Paint()..color = Colors.black87;
  canvas.drawCircle(Offset(w * 0.43, h * 0.31), w * 0.015, nostril);
  canvas.drawCircle(Offset(w * 0.57, h * 0.31), w * 0.015, nostril);
  final smoke = Paint()
    ..color = Colors.grey.withValues(alpha: 0.5 + 0.2 * sin(t * 4));
  canvas.drawCircle(Offset(w * 0.41, h * 0.26 - h * 0.02 * (t % 1)), w * 0.02, smoke);
  canvas.drawCircle(Offset(w * 0.59, h * 0.25 - h * 0.02 * ((t + 0.5) % 1)), w * 0.018, smoke);

  // Dientes
  final teeth = Paint()..color = Colors.white;
  for (var i = 0; i < 4; i++) {
    final x = w * (0.39 + i * 0.06);
    final fang = Path()
      ..moveTo(x, h * 0.38)
      ..lineTo(x + w * 0.02, h * 0.42)
      ..lineTo(x + w * 0.04, h * 0.38)
      ..close();
    canvas.drawPath(fang, teeth);
  }

  // Cuernos
  final horn = Paint()..color = const Color(0xFFE8E0D0);
  final leftHorn = Path()
    ..moveTo(w * 0.32, h * 0.12)
    ..lineTo(w * 0.22, h * 0.01)
    ..lineTo(w * 0.40, h * 0.08)
    ..close();
  final rightHorn = Path()
    ..moveTo(w * 0.68, h * 0.12)
    ..lineTo(w * 0.78, h * 0.01)
    ..lineTo(w * 0.60, h * 0.08)
    ..close();
  canvas.drawPath(leftHorn, horn);
  canvas.drawPath(rightHorn, horn);

  _angryEyes(canvas, Offset(w * 0.40, h * 0.19), Offset(w * 0.60, h * 0.19),
      w * 0.035, cfg.secondary, enrage);
}

// ── galaxy: Overlord Zenth ──────────────────────────────────────────────────

void _paintOverlord(
    Canvas canvas, Size size, BossConfig cfg, double t, int enrage) {
  final w = size.width;
  final h = size.height;

  // Haz tractor bajo el platillo
  final beam = Path()
    ..moveTo(w * 0.38, h * 0.60)
    ..lineTo(w * 0.24, h * 0.98)
    ..lineTo(w * 0.76, h * 0.98)
    ..lineTo(w * 0.62, h * 0.60)
    ..close();
  canvas.drawPath(
      beam,
      Paint()
        ..color = cfg.secondary
            .withValues(alpha: 0.18 + 0.08 * sin(t * 5)));

  // Cúpula de cristal con el alien dentro
  canvas.drawArc(
      Rect.fromLTWH(w * 0.26, h * 0.08, w * 0.48, h * 0.44),
      pi, pi, true,
      Paint()..color = Colors.lightBlue.withValues(alpha: 0.30));

  // Alien: cabeza verde con ojos negros enormes
  final alien = Paint()..color = const Color(0xFF7CB342);
  canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.26), width: w * 0.26, height: h * 0.20),
      alien);
  final eye = Paint()..color = Colors.black87;
  final er = w * (0.045 + enrage * 0.008);
  canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.44, h * 0.26), width: er * 2, height: er * 2.8),
      eye);
  canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.56, h * 0.26), width: er * 2, height: er * 2.8),
      eye);
  if (enrage > 0) {
    final glow = Paint()..color = Colors.red.withValues(alpha: 0.5);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.44, h * 0.26), width: er, height: er * 1.4),
        glow);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.56, h * 0.26), width: er, height: er * 1.4),
        glow);
  }

  // Platillo
  canvas.drawOval(Rect.fromLTWH(w * 0.05, h * 0.40, w * 0.90, h * 0.26),
      Paint()..color = cfg.primary);
  canvas.drawOval(Rect.fromLTWH(w * 0.05, h * 0.40, w * 0.90, h * 0.13),
      Paint()..color = _lighter(cfg.primary, 0.12));

  // Luces del borde (parpadean en secuencia)
  for (var i = 0; i < 5; i++) {
    final on = ((t * 4).floor() + i) % 5 == 0;
    canvas.drawCircle(
      Offset(w * (0.16 + i * 0.17), h * 0.56),
      w * 0.028,
      Paint()
        ..color = on ? cfg.secondary : _darker(cfg.primary, 0.15),
    );
  }
}

// ── jungle: Gran Gorila ─────────────────────────────────────────────────────

// Silueta de bruto: joroba con hombros sobre la cabeza, brazos enormes con
// los nudillos al suelo, piernas cortas, colmillos hacia arriba, pintura de
// guerra y taparrabos con cinturón dorado.
void _paintGorilla(
    Canvas canvas, Size size, BossConfig cfg, double t, int enrage) {
  final w = size.width;
  final h = size.height;
  final pound = (sin(t * 5) * h * 0.02) * (enrage > 0 ? 1.5 : 1.0);
  final body = Paint()..color = cfg.primary;
  final darkFur = Paint()..color = _darker(cfg.primary, 0.08);

  // Piernas cortas y arqueadas (detrás del taparrabos)
  canvas.drawOval(Rect.fromLTWH(w * 0.28, h * 0.68, w * 0.16, h * 0.28), body);
  canvas.drawOval(Rect.fromLTWH(w * 0.56, h * 0.68, w * 0.16, h * 0.28), body);

  // Torso jorobado: ancho de hombros arriba, se estrecha hacia la cadera
  final hump = Path()
    ..moveTo(w * 0.12, h * 0.22)
    ..quadraticBezierTo(w * 0.5, h * -0.02, w * 0.88, h * 0.22)
    ..quadraticBezierTo(w * 0.94, h * 0.48, w * 0.72, h * 0.74)
    ..lineTo(w * 0.28, h * 0.74)
    ..quadraticBezierTo(w * 0.06, h * 0.48, w * 0.12, h * 0.22)
    ..close();
  canvas.drawPath(hump, body);

  // Brazos desproporcionados: del hombro al suelo, más gruesos que las piernas
  canvas.drawOval(
      Rect.fromLTWH(w * -0.02, h * 0.16 + pound, w * 0.26, h * 0.56), darkFur);
  canvas.drawOval(
      Rect.fromLTWH(w * 0.76, h * 0.16 - pound, w * 0.26, h * 0.56), darkFur);
  // Puños-nudillos apoyados en el suelo
  canvas.drawCircle(Offset(w * 0.11, h * 0.84 + pound), w * 0.115, darkFur);
  canvas.drawCircle(Offset(w * 0.89, h * 0.84 - pound), w * 0.115, darkFur);
  final knuckle = Paint()
    ..color = Colors.black.withValues(alpha: 0.25)
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;
  for (final x in [w * 0.11, w * 0.89]) {
    final dy = x < w * 0.5 ? pound : -pound;
    canvas.drawLine(Offset(x - w * 0.05, h * 0.82 + dy),
        Offset(x - w * 0.05, h * 0.87 + dy), knuckle);
    canvas.drawLine(Offset(x + w * 0.05, h * 0.82 + dy),
        Offset(x + w * 0.05, h * 0.87 + dy), knuckle);
  }

  // Pecho claro
  canvas.drawOval(Rect.fromLTWH(w * 0.32, h * 0.34, w * 0.36, h * 0.30),
      Paint()..color = cfg.secondary);

  // Taparrabos azul con cinturón dorado (acento de color del atuendo)
  final cloth = Path()
    ..moveTo(w * 0.33, h * 0.66)
    ..lineTo(w * 0.67, h * 0.66)
    ..lineTo(w * 0.63, h * 0.80)
    ..lineTo(w * 0.55, h * 0.76)
    ..lineTo(w * 0.5, h * 0.86)
    ..lineTo(w * 0.45, h * 0.76)
    ..lineTo(w * 0.37, h * 0.80)
    ..close();
  canvas.drawPath(cloth, Paint()..color = Colors.blue.shade800);
  _rrect(canvas, Rect.fromLTWH(w * 0.31, h * 0.62, w * 0.38, h * 0.05),
      const Color(0xFFFFD700), 4);

  // Melena oscura que enmarca la cabeza hundida entre los hombros
  canvas.drawOval(Rect.fromLTWH(w * 0.30, h * 0.02, w * 0.40, h * 0.30),
      Paint()..color = _darker(cfg.primary, 0.16));

  // Cabeza pequeña, sin cuello, hundida en el torso
  canvas.drawOval(Rect.fromLTWH(w * 0.36, h * 0.06, w * 0.28, h * 0.24),
      Paint()..color = cfg.secondary);
  // Ceja pesada
  _rrect(canvas, Rect.fromLTWH(w * 0.37, h * 0.09, w * 0.26, h * 0.045),
      _darker(cfg.primary, 0.16), 4);

  // Pintura de guerra amarilla bajo los ojos
  final paintMark = Paint()
    ..color = Colors.yellow.shade600
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(Offset(w * 0.40, h * 0.185), Offset(w * 0.445, h * 0.20),
      paintMark);
  canvas.drawLine(Offset(w * 0.555, h * 0.20), Offset(w * 0.60, h * 0.185),
      paintMark);

  _angryEyes(canvas, Offset(w * 0.44, h * 0.155), Offset(w * 0.56, h * 0.155),
      w * 0.028, Colors.black87, enrage);

  // Nariz
  final nose = Paint()..color = Colors.black87;
  canvas.drawCircle(Offset(w * 0.475, h * 0.215), w * 0.012, nose);
  canvas.drawCircle(Offset(w * 0.525, h * 0.215), w * 0.012, nose);

  // Mandíbula protuberante con colmillos hacia ARRIBA
  _rrect(canvas, Rect.fromLTWH(w * 0.39, h * 0.24, w * 0.22, h * 0.05),
      Colors.black87, 5);
  final tusk = Paint()..color = const Color(0xFFFFF3D6);
  final tuskL = Path()
    ..moveTo(w * 0.41, h * 0.275)
    ..lineTo(w * 0.435, h * 0.225)
    ..lineTo(w * 0.46, h * 0.275)
    ..close();
  final tuskR = Path()
    ..moveTo(w * 0.54, h * 0.275)
    ..lineTo(w * 0.565, h * 0.225)
    ..lineTo(w * 0.59, h * 0.275)
    ..close();
  canvas.drawPath(tuskL, tusk);
  canvas.drawPath(tuskR, tusk);
}

// ── dark_city: Señor Sombra ─────────────────────────────────────────────────

void _paintShadow(
    Canvas canvas, Size size, BossConfig cfg, double t, int enrage) {
  final w = size.width;
  final h = size.height;

  // Volutas de humo púrpura ascendiendo
  final smoke = Paint()..color = cfg.attackColor.withValues(alpha: 0.35);
  for (var i = 0; i < 3; i++) {
    final phase = (t * 0.5 + i * 0.33) % 1.0;
    canvas.drawCircle(
      Offset(w * (0.22 + i * 0.28) + sin(t * 2 + i) * w * 0.03,
          h * (0.85 - phase * 0.55)),
      w * (0.05 - phase * 0.03),
      smoke,
    );
  }

  // Capa/túnica con borde inferior ondulado
  final cloak = Path()
    ..moveTo(w * 0.5, h * 0.02)
    ..lineTo(w * 0.16, h * 0.30)
    ..lineTo(w * 0.10, h * 0.94);
  for (var i = 0; i < 5; i++) {
    final x0 = w * (0.10 + i * 0.16);
    cloak
      ..lineTo(x0 + w * 0.08, h * 0.86)
      ..lineTo(x0 + w * 0.16, h * 0.94);
  }
  cloak
    ..lineTo(w * 0.90, h * 0.94)
    ..lineTo(w * 0.84, h * 0.30)
    ..close();
  canvas.drawPath(cloak, Paint()..color = cfg.primary);

  // Interior de la capucha (oscuridad total)
  canvas.drawOval(Rect.fromLTWH(w * 0.32, h * 0.10, w * 0.36, h * 0.26),
      Paint()..color = Colors.black);

  // Ojos brillantes
  final glowR = w * (0.035 + enrage * 0.008);
  final pulse = 0.7 + 0.3 * sin(t * 5);
  final eyeGlow = Paint()
    ..color = cfg.secondary.withValues(alpha: 0.45 * pulse);
  canvas.drawCircle(Offset(w * 0.43, h * 0.22), glowR * 2.0, eyeGlow);
  canvas.drawCircle(Offset(w * 0.57, h * 0.22), glowR * 2.0, eyeGlow);
  final eye = Paint()..color = cfg.secondary;
  canvas.drawCircle(Offset(w * 0.43, h * 0.22), glowR, eye);
  canvas.drawCircle(Offset(w * 0.57, h * 0.22), glowR, eye);

  // Emblema en el pecho
  final emblem = Path()
    ..moveTo(w * 0.5, h * 0.42)
    ..lineTo(w * 0.56, h * 0.50)
    ..lineTo(w * 0.5, h * 0.58)
    ..lineTo(w * 0.44, h * 0.50)
    ..close();
  canvas.drawPath(emblem, Paint()..color = cfg.secondary);
}

// ── ocean: Kraken Abisal ────────────────────────────────────────────────────

void _paintKraken(
    Canvas canvas, Size size, BossConfig cfg, double t, int enrage) {
  final w = size.width;
  final h = size.height;

  // Tentáculos ondulantes
  final tentacle = Paint()
    ..color = _darker(cfg.primary, 0.05)
    ..strokeWidth = w * 0.065
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  for (var i = 0; i < 6; i++) {
    final baseX = w * (0.16 + i * 0.135);
    final wave = sin(t * 3 + i * 1.1) * w * 0.05;
    final path = Path()
      ..moveTo(baseX, h * 0.58)
      ..quadraticBezierTo(
          baseX + wave, h * 0.78, baseX - wave * 1.4, h * 0.97);
    canvas.drawPath(path, tentacle);
    // Ventosas
    canvas.drawCircle(Offset(baseX + wave * 0.5, h * 0.78), w * 0.014,
        Paint()..color = cfg.secondary);
  }

  // Cabeza bulbosa
  canvas.drawOval(Rect.fromLTWH(w * 0.14, h * 0.04, w * 0.72, h * 0.60),
      Paint()..color = cfg.primary);
  // Manchas
  final spot = Paint()..color = _lighter(cfg.primary, 0.12);
  canvas.drawCircle(Offset(w * 0.30, h * 0.16), w * 0.035, spot);
  canvas.drawCircle(Offset(w * 0.68, h * 0.12), w * 0.028, spot);
  canvas.drawCircle(Offset(w * 0.55, h * 0.08), w * 0.02, spot);

  // Ojos grandes con esclerótica amarilla
  final sclera = Paint()..color = const Color(0xFFFFF176);
  final pupilR = w * (0.035 + enrage * 0.008);
  canvas.drawCircle(Offset(w * 0.38, h * 0.34), w * 0.085, sclera);
  canvas.drawCircle(Offset(w * 0.62, h * 0.34), w * 0.085, sclera);
  final pupil = Paint()..color = Colors.black87;
  final look = sin(t * 1.5) * w * 0.015;
  canvas.drawCircle(Offset(w * 0.38 + look, h * 0.34), pupilR, pupil);
  canvas.drawCircle(Offset(w * 0.62 + look, h * 0.34), pupilR, pupil);
  if (enrage > 0) {
    final vein = Paint()
      ..color = Colors.red.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.32, h * 0.30), Offset(w * 0.36, h * 0.33), vein);
    canvas.drawLine(Offset(w * 0.68, h * 0.30), Offset(w * 0.64, h * 0.33), vein);
  }

  // Pico
  final beak = Path()
    ..moveTo(w * 0.46, h * 0.48)
    ..lineTo(w * 0.54, h * 0.48)
    ..lineTo(w * 0.5, h * 0.56)
    ..close();
  canvas.drawPath(beak, Paint()..color = _darker(cfg.primary, 0.25));
}

// ── tundra: Yeti Glacial ────────────────────────────────────────────────────

// Misma silueta de bruto que el gorila: joroba blanca, nudillos al suelo,
// cabeza hundida, colmillos hacia arriba y pintura de guerra azul hielo.
void _paintYeti(
    Canvas canvas, Size size, BossConfig cfg, double t, int enrage) {
  final w = size.width;
  final h = size.height;
  final fur = Paint()..color = cfg.primary;
  final shadowFur = Paint()..color = _darker(cfg.primary, 0.10);
  final roar = sin(t * 2.5) * h * 0.015;

  // Copos de nieve alrededor
  final flake = Paint()..color = Colors.white.withValues(alpha: 0.8);
  for (var i = 0; i < 5; i++) {
    final phase = (t * 0.3 + i * 0.2) % 1.0;
    canvas.drawCircle(
        Offset(w * (0.08 + i * 0.21), h * phase), w * 0.012, flake);
  }

  // Piernas cortas y arqueadas
  canvas.drawOval(Rect.fromLTWH(w * 0.28, h * 0.70, w * 0.16, h * 0.26), fur);
  canvas.drawOval(Rect.fromLTWH(w * 0.56, h * 0.70, w * 0.16, h * 0.26), fur);

  // Torso jorobado: hombros por encima de la cabeza
  final hump = Path()
    ..moveTo(w * 0.13, h * 0.24)
    ..quadraticBezierTo(w * 0.5, h * 0.00, w * 0.87, h * 0.24)
    ..quadraticBezierTo(w * 0.93, h * 0.50, w * 0.72, h * 0.76)
    ..lineTo(w * 0.28, h * 0.76)
    ..quadraticBezierTo(w * 0.07, h * 0.50, w * 0.13, h * 0.24)
    ..close();
  canvas.drawPath(hump, fur);

  // Picos de pelaje en los hombros
  for (final xs in [
    [0.16, 0.22, 0.28],
    [0.72, 0.78, 0.84],
  ]) {
    final spike = Path()
      ..moveTo(w * xs[0], h * 0.18)
      ..lineTo(w * xs[1], h * 0.06)
      ..lineTo(w * xs[2], h * 0.16)
      ..close();
    canvas.drawPath(spike, fur);
  }

  // Brazos al suelo con puños-nudillos
  canvas.drawOval(
      Rect.fromLTWH(w * -0.02, h * 0.18 + roar, w * 0.26, h * 0.54),
      shadowFur);
  canvas.drawOval(
      Rect.fromLTWH(w * 0.76, h * 0.18 - roar, w * 0.26, h * 0.54),
      shadowFur);
  canvas.drawCircle(Offset(w * 0.11, h * 0.84 + roar), w * 0.115, shadowFur);
  canvas.drawCircle(Offset(w * 0.89, h * 0.84 - roar), w * 0.115, shadowFur);
  // Garras de hielo sobre los nudillos
  final claw = Paint()
    ..color = cfg.secondary
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  for (var i = -1; i <= 1; i++) {
    canvas.drawLine(
        Offset(w * 0.11 + i * w * 0.045, h * 0.79 + roar),
        Offset(w * 0.11 + i * w * 0.055, h * 0.73 + roar),
        claw);
    canvas.drawLine(
        Offset(w * 0.89 + i * w * 0.045, h * 0.79 - roar),
        Offset(w * 0.89 + i * w * 0.055, h * 0.73 - roar),
        claw);
  }

  // Vientre claro
  canvas.drawOval(Rect.fromLTWH(w * 0.33, h * 0.38, w * 0.34, h * 0.30),
      Paint()..color = _lighter(cfg.secondary, 0.16));

  // Taparrabos de pelaje oscuro con amuleto de hielo
  final cloth = Path()
    ..moveTo(w * 0.33, h * 0.68)
    ..lineTo(w * 0.67, h * 0.68)
    ..lineTo(w * 0.63, h * 0.79)
    ..lineTo(w * 0.555, h * 0.76)
    ..lineTo(w * 0.5, h * 0.86)
    ..lineTo(w * 0.445, h * 0.76)
    ..lineTo(w * 0.37, h * 0.79)
    ..close();
  canvas.drawPath(cloth, Paint()..color = const Color(0xFF4A6B8A));
  final gem = Path()
    ..moveTo(w * 0.5, h * 0.63)
    ..lineTo(w * 0.535, h * 0.675)
    ..lineTo(w * 0.5, h * 0.72)
    ..lineTo(w * 0.465, h * 0.675)
    ..close();
  canvas.drawPath(gem, Paint()..color = cfg.secondary);

  // Cabeza hundida entre los hombros, sin cuello
  canvas.drawOval(Rect.fromLTWH(w * 0.34, h * 0.07, w * 0.32, h * 0.26), fur);
  // Cara azul hielo
  canvas.drawOval(Rect.fromLTWH(w * 0.38, h * 0.10, w * 0.24, h * 0.21),
      Paint()..color = cfg.secondary);
  // Ceja pesada de pelaje
  _rrect(canvas, Rect.fromLTWH(w * 0.375, h * 0.115, w * 0.25, h * 0.04),
      _darker(cfg.primary, 0.06), 4);

  // Pintura de guerra azul oscuro bajo los ojos
  final paintMark = Paint()
    ..color = const Color(0xFF01579B)
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(
      Offset(w * 0.405, h * 0.205), Offset(w * 0.445, h * 0.22), paintMark);
  canvas.drawLine(
      Offset(w * 0.555, h * 0.22), Offset(w * 0.595, h * 0.205), paintMark);

  _angryEyes(canvas, Offset(w * 0.445, h * 0.175), Offset(w * 0.555, h * 0.175),
      w * 0.028, const Color(0xFF01579B), enrage);

  // Mandíbula protuberante con colmillos hacia ARRIBA
  _rrect(canvas, Rect.fromLTWH(w * 0.40, h * 0.25, w * 0.20, h * 0.05),
      const Color(0xFF01579B), 5);
  final tusk = Paint()..color = Colors.white;
  final tuskL = Path()
    ..moveTo(w * 0.42, h * 0.285)
    ..lineTo(w * 0.445, h * 0.235)
    ..lineTo(w * 0.47, h * 0.285)
    ..close();
  final tuskR = Path()
    ..moveTo(w * 0.53, h * 0.285)
    ..lineTo(w * 0.555, h * 0.235)
    ..lineTo(w * 0.58, h * 0.285)
    ..close();
  canvas.drawPath(tuskL, tusk);
  canvas.drawPath(tuskR, tusk);
}

// ── robot_city: Mega-Bot X9 ─────────────────────────────────────────────────

void _paintMegaBot(
    Canvas canvas, Size size, BossConfig cfg, double t, int enrage) {
  final w = size.width;
  final h = size.height;

  // Antena con luz parpadeante
  canvas.drawLine(
      Offset(w * 0.5, h * 0.10),
      Offset(w * 0.5, h * 0.01),
      Paint()
        ..color = Colors.grey.shade500
        ..strokeWidth = 2.5);
  final blink = (sin(t * 7) + 1) / 2;
  canvas.drawCircle(Offset(w * 0.5, h * 0.01), w * 0.02,
      Paint()..color = cfg.attackColor.withValues(alpha: 0.4 + 0.6 * blink));

  // Cañones de hombro con misiles
  _rrect(canvas, Rect.fromLTWH(w * 0.04, h * 0.30, w * 0.16, h * 0.14),
      _darker(cfg.primary, 0.12), 4);
  _rrect(canvas, Rect.fromLTWH(w * 0.80, h * 0.30, w * 0.16, h * 0.14),
      _darker(cfg.primary, 0.12), 4);
  final missileTip = Paint()..color = cfg.attackColor;
  canvas.drawCircle(Offset(w * 0.12, h * 0.30), w * 0.028, missileTip);
  canvas.drawCircle(Offset(w * 0.88, h * 0.30), w * 0.028, missileTip);

  // Torso angular con paneles
  _rrect(canvas, Rect.fromLTWH(w * 0.22, h * 0.38, w * 0.56, h * 0.40),
      cfg.primary, 6);
  final panel = Paint()
    ..color = Colors.black.withValues(alpha: 0.25)
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;
  canvas.drawLine(Offset(w * 0.35, h * 0.38), Offset(w * 0.35, h * 0.78), panel);
  canvas.drawLine(Offset(w * 0.65, h * 0.38), Offset(w * 0.65, h * 0.78), panel);

  // Núcleo de energía
  final corePulse = 0.75 + 0.25 * sin(t * 4);
  canvas.drawCircle(Offset(w * 0.5, h * 0.56), w * 0.085,
      Paint()..color = cfg.secondary.withValues(alpha: 0.30 * corePulse));
  canvas.drawCircle(Offset(w * 0.5, h * 0.56), w * 0.05,
      Paint()..color = cfg.secondary.withValues(alpha: corePulse));

  // Orugas / base
  _rrect(canvas, Rect.fromLTWH(w * 0.18, h * 0.80, w * 0.64, h * 0.16),
      _darker(cfg.primary, 0.18), 8);
  final wheel = Paint()..color = Colors.black54;
  for (var i = 0; i < 4; i++) {
    canvas.drawCircle(
        Offset(w * (0.27 + i * 0.155), h * 0.88), w * 0.035, wheel);
  }

  // Cabeza con visor escáner
  _rrect(canvas, Rect.fromLTWH(w * 0.30, h * 0.12, w * 0.40, h * 0.22),
      _lighter(cfg.primary, 0.06), 6);
  _rrect(canvas, Rect.fromLTWH(w * 0.34, h * 0.18, w * 0.32, h * 0.08),
      Colors.black87, 4);
  // Línea de escaneo que va y viene; en furia se vuelve roja
  final scanX = w * (0.36 + 0.26 * (0.5 + 0.5 * sin(t * 3)));
  canvas.drawRect(
      Rect.fromLTWH(scanX, h * 0.185, w * 0.03, h * 0.07),
      Paint()..color = enrage > 0 ? cfg.attackColor : cfg.secondary);
}

// ── Ataques ─────────────────────────────────────────────────────────────────

/// Dibuja un ataque del jefe ocupando [size]. El proyectil es temático por
/// mundo; la onda de choque y el barrido comparten forma pero usan los
/// colores del jefe del mundo.
void paintBossAttack(
  Canvas canvas,
  Size size,
  BossAttackKind kind,
  String worldId, {
  double animT = 0,
}) {
  final cfg = bossFor(worldId);
  switch (kind) {
    case BossAttackKind.projectile:
      _paintProjectile(canvas, size, worldId, cfg, animT);
    case BossAttackKind.shockwave:
      _paintShockwave(canvas, size, cfg, animT);
    case BossAttackKind.sweep:
      _paintSweep(canvas, size, worldId, cfg, animT);
  }
}

void _paintProjectile(
    Canvas canvas, Size size, String worldId, BossConfig cfg, double t) {
  final w = size.width;
  final h = size.height;
  final c = Offset(w / 2, h / 2);
  final r = min(w, h) / 2;

  switch (worldId) {
    case 'medieval':
      // Bola de fuego
      canvas.drawCircle(c, r,
          Paint()..color = cfg.attackColor.withValues(alpha: 0.45));
      canvas.drawCircle(c, r * 0.75, Paint()..color = cfg.attackColor);
      canvas.drawCircle(c, r * 0.42, Paint()..color = Colors.yellow.shade600);
    case 'galaxy':
      // Orbe de energía con anillos
      canvas.drawCircle(c, r,
          Paint()..color = cfg.attackColor.withValues(alpha: 0.35));
      canvas.drawCircle(c, r * 0.55, Paint()..color = cfg.attackColor);
      canvas.drawCircle(
          c,
          r * (0.7 + 0.15 * sin(t * 8)),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    case 'jungle':
      // Barril de madera
      _rrect(canvas, Rect.fromLTWH(w * 0.12, h * 0.06, w * 0.76, h * 0.88),
          cfg.attackColor, 8);
      final band = Paint()..color = Colors.black.withValues(alpha: 0.35);
      canvas.drawRect(Rect.fromLTWH(w * 0.12, h * 0.24, w * 0.76, h * 0.09), band);
      canvas.drawRect(Rect.fromLTWH(w * 0.12, h * 0.66, w * 0.76, h * 0.09), band);
    case 'dark_city':
      // Orbe de sombra
      canvas.drawCircle(c, r,
          Paint()..color = cfg.attackColor.withValues(alpha: 0.35));
      canvas.drawCircle(c, r * 0.65, Paint()..color = cfg.primary);
      canvas.drawCircle(c, r * 0.3, Paint()..color = cfg.secondary);
    case 'ocean':
      // Chorro de agua
      canvas.drawCircle(c, r * 0.8, Paint()..color = cfg.attackColor);
      canvas.drawCircle(Offset(c.dx - r * 0.25, c.dy - r * 0.25), r * 0.25,
          Paint()..color = Colors.white.withValues(alpha: 0.55));
      canvas.drawCircle(Offset(c.dx + r * 0.6, c.dy - r * 0.5), r * 0.18,
          Paint()..color = cfg.attackColor.withValues(alpha: 0.7));
    case 'tundra':
      // Bola de nieve
      canvas.drawCircle(c, r * 0.85, Paint()..color = Colors.white);
      final speck = Paint()..color = cfg.secondary;
      canvas.drawCircle(Offset(c.dx - r * 0.3, c.dy - r * 0.1), r * 0.09, speck);
      canvas.drawCircle(Offset(c.dx + r * 0.25, c.dy + r * 0.3), r * 0.07, speck);
      canvas.drawCircle(Offset(c.dx + r * 0.1, c.dy - r * 0.35), r * 0.06, speck);
    case 'robot_city':
      // Misil de frente: cuerpo + punta roja + aletas
      canvas.drawCircle(c, r * 0.75, Paint()..color = Colors.grey.shade500);
      canvas.drawCircle(c, r * 0.45, Paint()..color = cfg.attackColor);
      final fin = Paint()..color = Colors.grey.shade700;
      for (var i = 0; i < 4; i++) {
        final ang = i * pi / 2 + pi / 4;
        canvas.drawLine(
            c + Offset(cos(ang), sin(ang)) * r * 0.7,
            c + Offset(cos(ang), sin(ang)) * r,
            fin..strokeWidth = 4);
      }
    default:
      // lego_city: bola de demolición con cadena
      canvas.drawCircle(c, r * 0.85, Paint()..color = cfg.attackColor);
      canvas.drawCircle(Offset(c.dx - r * 0.28, c.dy - r * 0.28), r * 0.2,
          Paint()..color = Colors.white.withValues(alpha: 0.3));
      canvas.drawCircle(
          Offset(c.dx, c.dy - r * 0.9),
          r * 0.18,
          Paint()
            ..color = Colors.grey.shade600
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
  }
}

void _paintShockwave(Canvas canvas, Size size, BossConfig cfg, double t) {
  final w = size.width;
  final h = size.height;

  // Banda baja de energía a lo ancho de la pista
  _rrect(canvas, Rect.fromLTWH(0, h * 0.35, w, h * 0.65),
      cfg.attackColor.withValues(alpha: 0.85), 6);

  // Crestas de la onda
  final crest = Paint()..color = Colors.white.withValues(alpha: 0.75);
  final n = max(3, (w / 34).floor());
  for (var i = 0; i < n; i++) {
    final x = w * (i + 0.5) / n + sin(t * 6 + i) * 2;
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(x, h * 0.38), width: w / n * 0.8, height: h * 0.5),
        pi, pi, true, crest);
  }
}

void _paintSweep(
    Canvas canvas, Size size, String worldId, BossConfig cfg, double t) {
  final w = size.width;
  final h = size.height;
  final isLaser = worldId == 'galaxy' || worldId == 'robot_city';

  if (isLaser) {
    final pulse = 0.75 + 0.25 * sin(t * 9);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, w, h), Radius.circular(h / 2)),
        Paint()..color = cfg.attackColor.withValues(alpha: 0.30 * pulse));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, h * 0.28, w, h * 0.44),
            Radius.circular(h * 0.22)),
        Paint()..color = cfg.attackColor.withValues(alpha: 0.95 * pulse));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, h * 0.42, w, h * 0.16),
            Radius.circular(h * 0.08)),
        Paint()..color = Colors.white.withValues(alpha: 0.85 * pulse));
    return;
  }

  // Barra sólida temática
  _rrect(canvas, Rect.fromLTWH(0, h * 0.15, w, h * 0.70), cfg.attackColor, 8);

  switch (worldId) {
    case 'medieval':
      // Cola de dragón con púas
      final spike = Paint()..color = _darker(cfg.attackColor, 0.15);
      final n = max(3, (w / 40).floor());
      for (var i = 0; i < n; i++) {
        final x = w * (i + 0.5) / n;
        final p = Path()
          ..moveTo(x - 7, h * 0.16)
          ..lineTo(x, 0)
          ..lineTo(x + 7, h * 0.16)
          ..close();
        canvas.drawPath(p, spike);
      }
    case 'ocean':
      // Tentáculo con ventosas
      final sucker = Paint()..color = cfg.secondary;
      final n = max(3, (w / 36).floor());
      for (var i = 0; i < n; i++) {
        canvas.drawCircle(
            Offset(w * (i + 0.5) / n, h * 0.5), h * 0.14, sucker);
      }
    case 'tundra':
      // Barra de hielo con carámbanos
      final ice = Paint()..color = Colors.white.withValues(alpha: 0.85);
      final n = max(3, (w / 44).floor());
      for (var i = 0; i < n; i++) {
        final x = w * (i + 0.5) / n;
        final p = Path()
          ..moveTo(x - 5, h * 0.84)
          ..lineTo(x, h)
          ..lineTo(x + 5, h * 0.84)
          ..close();
        canvas.drawPath(p, ice);
      }
      canvas.drawRect(Rect.fromLTWH(0, h * 0.15, w, h * 0.18), ice);
    default:
      // Franjas de peligro (lego_city, jungle, dark_city)
      final dark = Paint()..color = Colors.black.withValues(alpha: 0.30);
      final n = max(4, (w / 30).floor());
      for (var i = 0; i < n; i++) {
        if (i.isOdd) continue;
        canvas.drawRect(
            Rect.fromLTWH(w * i / n, h * 0.15, w / n, h * 0.70), dark);
      }
  }
}
