import 'package:flutter/material.dart';

import '../../domain/entities/character.dart';

/// Paleta compartida entre la vista previa del editor y el jugador del juego,
/// para que el mismo personaje se vea igual en ambos lados. Cada valor de
/// enum tiene un color propio — ninguna opción cae a un color genérico.

Color skinColorFor(SkinTone tone) => switch (tone) {
      SkinTone.light => const Color(0xFFFFDBAC),
      SkinTone.medium => const Color(0xFFD4A574),
      SkinTone.dark => const Color(0xFF8D5524),
      SkinTone.blue => Colors.blue.shade400,
      SkinTone.green => Colors.green.shade400,
      SkinTone.purple => Colors.purple.shade400,
      SkinTone.orange => Colors.orange.shade400,
      SkinTone.silver => Colors.grey.shade400,
      SkinTone.gold => const Color(0xFFFFD700),
    };

Color torsoColorFor(TorsoDesign design) => switch (design) {
      TorsoDesign.plain => Colors.red.shade400,
      TorsoDesign.police => Colors.blue.shade800,
      TorsoDesign.firefighter => Colors.red.shade800,
      TorsoDesign.astronaut => Colors.grey.shade300,
      TorsoDesign.doctor => Colors.white,
      TorsoDesign.chef => const Color(0xFFF0EEE6),
      TorsoDesign.military => Colors.green.shade800,
      TorsoDesign.ninja => Colors.black,
      TorsoDesign.pirate => Colors.brown.shade700,
      TorsoDesign.superhero => Colors.blue.shade600,
      TorsoDesign.casual => Colors.teal.shade400,
      TorsoDesign.medieval => Colors.grey.shade600,
      TorsoDesign.futuristic => Colors.cyan.shade700,
      TorsoDesign.samurai => const Color(0xFF6D1B1B),
      TorsoDesign.dinosaur => Colors.green.shade600,
      TorsoDesign.robot => Colors.blueGrey.shade400,
      TorsoDesign.monster => Colors.purple.shade600,
      TorsoDesign.alien => Colors.lightGreen.shade600,
    };

Color legColorFor(LegDesign design) => switch (design) {
      LegDesign.plain => Colors.blue.shade700,
      LegDesign.camouflage => Colors.green.shade700,
      LegDesign.stripes => Colors.red.shade600,
      LegDesign.checkered => Colors.white,
      LegDesign.flames => Colors.grey.shade900,
      LegDesign.stars => Colors.indigo.shade700,
      LegDesign.armor => Colors.grey.shade600,
    };

/// [skin] se usa para sandalias y pies descalzos.
Color shoeColorFor(ShoeType shoe, Color skin) => switch (shoe) {
      ShoeType.sneakers => Colors.white,
      ShoeType.military => Colors.brown.shade800,
      ShoeType.cowboy => Colors.brown.shade600,
      ShoeType.sandals => skin,
      ShoeType.skates => Colors.grey.shade300,
      ShoeType.flippers => Colors.blue.shade600,
      ShoeType.witchBoots => Colors.black,
      ShoeType.barefoot => skin,
    };

Color hairColorFor(HairStyle style) => switch (style) {
      HairStyle.straight => Colors.brown.shade700,
      HairStyle.curly => Colors.black87,
      HairStyle.afro => const Color(0xFF3E2723),
      HairStyle.mohawk => Colors.red.shade700,
      HairStyle.ponytail => Colors.amber.shade400,
      HairStyle.braids => Colors.brown.shade400,
      HairStyle.shaved => Colors.grey.shade800,
      HairStyle.bald => Colors.transparent,
    };

Color helmetColorFor(HelmetStyle style) => switch (style) {
      HelmetStyle.medieval => Colors.grey.shade600,
      HelmetStyle.space => Colors.white,
      HelmetStyle.roman => Colors.red.shade700,
      HelmetStyle.viking => Colors.grey.shade400,
      HelmetStyle.firefighter => Colors.yellow.shade700,
      HelmetStyle.biker => Colors.black,
      HelmetStyle.astronaut => const Color(0xFFECEFF1),
    };

Color hatColorFor(HatStyle style) => switch (style) {
      HatStyle.wizard => Colors.indigo.shade700,
      HatStyle.cowboy => Colors.brown.shade500,
      HatStyle.cap => Colors.red.shade600,
      HatStyle.crown => const Color(0xFFFFD700),
      HatStyle.tiara => const Color(0xFFE0E0E0),
      HatStyle.topHat => Colors.black,
      HatStyle.pirate => Colors.black,
    };

Color gloveColorFor(GloveType glove, Color skin) => switch (glove) {
      GloveType.none => skin,
      GloveType.boxing => Colors.red.shade700,
      GloveType.medieval => Colors.grey.shade500,
      GloveType.superhero => Colors.blue.shade800,
      GloveType.claws => Colors.grey.shade900,
    };

/// Dibuja el patrón del diseño de piernas dentro de [rect] (ya pintado con
/// [legColorFor]). Se recorta al rectángulo para que el patrón no se salga.
void paintLegPattern(Canvas canvas, Rect rect, LegDesign design) {
  canvas.save();
  canvas.clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)));
  switch (design) {
    case LegDesign.plain:
      break;
    case LegDesign.camouflage:
      final blotch = Paint()..color = Colors.green.shade900;
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(
                  rect.left + rect.width * 0.3, rect.top + rect.height * 0.25),
              width: rect.width * 0.55,
              height: rect.height * 0.18),
          blotch);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(
                  rect.left + rect.width * 0.75, rect.top + rect.height * 0.55),
              width: rect.width * 0.5,
              height: rect.height * 0.16),
          blotch);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(
                  rect.left + rect.width * 0.35, rect.top + rect.height * 0.8),
              width: rect.width * 0.5,
              height: rect.height * 0.15),
          blotch);
    case LegDesign.stripes:
      final stripe = Paint()..color = Colors.white;
      for (var i = 0; i < 3; i++) {
        canvas.drawRect(
            Rect.fromLTWH(rect.left, rect.top + rect.height * (0.18 + i * 0.28),
                rect.width, rect.height * 0.10),
            stripe);
      }
    case LegDesign.checkered:
      final black = Paint()..color = Colors.black87;
      final cell = rect.width / 2;
      var row = 0;
      for (var y = rect.top; y < rect.bottom; y += cell, row++) {
        for (var col = 0; col < 2; col++) {
          if ((row + col).isEven) {
            canvas.drawRect(
                Rect.fromLTWH(rect.left + col * cell, y, cell, cell), black);
          }
        }
      }
    case LegDesign.flames:
      final flame = Paint()..color = Colors.orange.shade700;
      final inner = Paint()..color = Colors.yellow.shade600;
      final path = Path()..moveTo(rect.left, rect.bottom);
      for (var i = 0; i < 3; i++) {
        final x0 = rect.left + rect.width * (i / 3);
        final x1 = rect.left + rect.width * ((i + 0.5) / 3);
        final x2 = rect.left + rect.width * ((i + 1) / 3);
        path
          ..lineTo(x0, rect.bottom)
          ..lineTo(x1, rect.bottom - rect.height * 0.38)
          ..lineTo(x2, rect.bottom);
      }
      path.close();
      canvas.drawPath(path, flame);
      canvas.drawPath(path.shift(Offset(0, rect.height * 0.14)), inner);
    case LegDesign.stars:
      final starPaint = Paint()..color = Colors.white;
      drawStar4(
          canvas,
          Offset(rect.left + rect.width * 0.3, rect.top + rect.height * 0.25),
          rect.width * 0.14,
          starPaint);
      drawStar4(
          canvas,
          Offset(rect.left + rect.width * 0.7, rect.top + rect.height * 0.5),
          rect.width * 0.12,
          starPaint);
      drawStar4(
          canvas,
          Offset(rect.left + rect.width * 0.35, rect.top + rect.height * 0.78),
          rect.width * 0.13,
          starPaint);
    case LegDesign.armor:
      final line = Paint()
        ..color = Colors.grey.shade800
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      for (var i = 1; i <= 3; i++) {
        final y = rect.top + rect.height * i / 4;
        canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), line);
      }
      final rivet = Paint()..color = Colors.grey.shade300;
      canvas.drawCircle(
          Offset(rect.center.dx, rect.top + rect.height * 0.12), 1.8, rivet);
      canvas.drawCircle(
          Offset(rect.center.dx, rect.top + rect.height * 0.62), 1.8, rivet);
  }
  canvas.restore();
}

/// Estrella de 4 puntas.
void drawStar4(Canvas canvas, Offset center, double r, Paint paint) {
  final inner = r * 0.38;
  final path = Path()
    ..moveTo(center.dx, center.dy - r)
    ..lineTo(center.dx + inner, center.dy - inner)
    ..lineTo(center.dx + r, center.dy)
    ..lineTo(center.dx + inner, center.dy + inner)
    ..lineTo(center.dx, center.dy + r)
    ..lineTo(center.dx - inner, center.dy + inner)
    ..lineTo(center.dx - r, center.dy)
    ..lineTo(center.dx - inner, center.dy - inner)
    ..close();
  canvas.drawPath(path, paint);
}
