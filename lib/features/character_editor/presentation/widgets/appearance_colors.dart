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
      TorsoDesign.tactical => const Color(0xFF23272B),
      TorsoDesign.tanktop => const Color(0xFF8E9499),
      TorsoDesign.commando => const Color(0xFF4E5D3A),
      TorsoDesign.golden => const Color(0xFFD4AF37),
    };

Color legColorFor(LegDesign design) => switch (design) {
      LegDesign.plain => Colors.blue.shade700,
      LegDesign.camouflage => Colors.green.shade700,
      LegDesign.stripes => Colors.red.shade600,
      LegDesign.checkered => Colors.white,
      LegDesign.flames => Colors.grey.shade900,
      LegDesign.stars => Colors.indigo.shade700,
      LegDesign.armor => Colors.grey.shade600,
      LegDesign.desertCamo => const Color(0xFFC2B280),
      LegDesign.mechanic => const Color(0xFF212121),
      LegDesign.urbanCamo => const Color(0xFF3A3F44),
      LegDesign.golden => const Color(0xFFD4AF37),
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
      HairStyle.messy => const Color(0xFFB4622D),
      HairStyle.swept => const Color(0xFF7E2A22),
      HairStyle.fringe => const Color(0xFF1C1C1C),
    };

Color helmetColorFor(HelmetStyle style) => switch (style) {
      HelmetStyle.medieval => Colors.grey.shade600,
      HelmetStyle.space => Colors.white,
      HelmetStyle.roman => Colors.red.shade700,
      HelmetStyle.viking => Colors.grey.shade400,
      HelmetStyle.firefighter => Colors.yellow.shade700,
      HelmetStyle.biker => Colors.black,
      HelmetStyle.astronaut => const Color(0xFFECEFF1),
      HelmetStyle.ninjaHood => const Color(0xFFB8860B),
      HelmetStyle.ironMan => Colors.red.shade700,
      HelmetStyle.spiderMan => Colors.red.shade600,
      HelmetStyle.blackPanther => const Color(0xFF1A1A1A),
      HelmetStyle.deadpool => Colors.red.shade800,
      HelmetStyle.wolverine => Colors.amber.shade700,
    };

Color hatColorFor(HatStyle style) => switch (style) {
      HatStyle.wizard => Colors.indigo.shade700,
      HatStyle.cowboy => Colors.brown.shade500,
      HatStyle.cap => Colors.red.shade600,
      HatStyle.crown => const Color(0xFFFFD700),
      HatStyle.tiara => const Color(0xFFE0E0E0),
      HatStyle.topHat => Colors.black,
      HatStyle.pirate => Colors.black,
      HatStyle.conical => Colors.brown.shade400,
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
    case LegDesign.golden:
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
    case LegDesign.desertCamo:
      // Camuflaje desierto: manchas marrones y grises + correa de equipo
      final blotchA = Paint()..color = const Color(0xFF8B7355);
      final blotchB = Paint()..color = const Color(0xFF9E9E8E);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(rect.left + rect.width * 0.32,
                  rect.top + rect.height * 0.22),
              width: rect.width * 0.5,
              height: rect.height * 0.15),
          blotchA);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(rect.left + rect.width * 0.72,
                  rect.top + rect.height * 0.50),
              width: rect.width * 0.45,
              height: rect.height * 0.14),
          blotchB);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(rect.left + rect.width * 0.35,
                  rect.top + rect.height * 0.76),
              width: rect.width * 0.45,
              height: rect.height * 0.13),
          blotchA);
      // Correa con hebilla a la altura del muslo
      canvas.drawRect(
          Rect.fromLTWH(rect.left, rect.top + rect.height * 0.36,
              rect.width, rect.height * 0.05),
          Paint()..color = const Color(0xFF5D4E37));
    case LegDesign.mechanic:
      // Estilo mecánico: franja roja lateral, guiones azules y rodillera
      canvas.drawRect(
          Rect.fromLTWH(rect.left + rect.width * 0.10, rect.top,
              rect.width * 0.10, rect.height),
          Paint()..color = const Color(0xFFC62828));
      final dash = Paint()..color = const Color(0xFF2196F3);
      for (var i = 0; i < 3; i++) {
        canvas.drawRect(
            Rect.fromLTWH(rect.left + rect.width * 0.68,
                rect.top + rect.height * (0.55 + i * 0.10),
                rect.width * 0.16, rect.height * 0.04),
            dash);
      }
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(rect.center.dx, rect.top + rect.height * 0.34),
              width: rect.width * 0.5,
              height: rect.height * 0.16),
          Paint()..color = const Color(0xFF9EA7AD));
    case LegDesign.urbanCamo:
      // Camuflaje urbano: parches grises angulosos sobre fondo oscuro
      final patchA = Paint()..color = const Color(0xFF5C666E);
      final patchB = Paint()..color = const Color(0xFF23272B);
      final p1 = Path()
        ..moveTo(rect.left, rect.top + rect.height * 0.15)
        ..lineTo(rect.left + rect.width * 0.55, rect.top + rect.height * 0.10)
        ..lineTo(rect.left + rect.width * 0.35, rect.top + rect.height * 0.32)
        ..close();
      final p2 = Path()
        ..moveTo(rect.right, rect.top + rect.height * 0.45)
        ..lineTo(rect.left + rect.width * 0.40, rect.top + rect.height * 0.55)
        ..lineTo(rect.right - rect.width * 0.15, rect.top + rect.height * 0.70)
        ..close();
      final p3 = Path()
        ..moveTo(rect.left + rect.width * 0.15, rect.top + rect.height * 0.78)
        ..lineTo(rect.left + rect.width * 0.60, rect.top + rect.height * 0.85)
        ..lineTo(rect.left + rect.width * 0.25, rect.top + rect.height * 0.95)
        ..close();
      canvas.drawPath(p1, patchA);
      canvas.drawPath(p2, patchB);
      canvas.drawPath(p3, patchA);
  }
  canvas.restore();
}

// ── Acabado de plástico LEGO ──────────────────────────────────────────────────
// Helpers compartidos por el editor y el juego para que cada pieza se pinte
// como plástico ABS brillante: degradado de luz cenital, reflejo especular y
// contorno tonal (una versión oscura del propio color, nunca negro plano).

Color lightenColor(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
      .toColor();
}

Color darkenColor(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
      .toColor();
}

/// Contorno tonal: oscuro y saturado en piezas claras, sutil en oscuras.
Paint outlinePaintFor(Color color, {double width = 1.4}) => Paint()
  ..color = darkenColor(color, 0.28).withValues(alpha: 0.85)
  ..style = PaintingStyle.stroke
  ..strokeWidth = width;

/// Rectángulo redondeado con acabado de plástico brillante: degradado
/// vertical (luz desde arriba), banda de reflejo y contorno tonal.
void drawPlasticRect(Canvas canvas, Rect rect, Color color, double radius,
    {bool sheen = true}) {
  final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
  canvas.drawRRect(
    rrect,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lightenColor(color, 0.10), color, darkenColor(color, 0.12)],
        stops: const [0.0, 0.52, 1.0],
      ).createShader(rect),
  );

  if (sheen && rect.width > 10 && rect.height > 10) {
    final sheenRect = Rect.fromLTWH(
      rect.left + rect.width * 0.10,
      rect.top + rect.height * 0.07,
      rect.width * 0.42,
      (rect.height * 0.14).clamp(2.0, 10.0),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sheenRect, Radius.circular(radius * 0.8)),
      Paint()..color = Colors.white.withValues(alpha: 0.20),
    );
  }

  final ow = (rect.shortestSide * 0.10).clamp(0.9, 1.5);
  canvas.drawRRect(rrect, outlinePaintFor(color, width: ow));
}

/// Esfera de plástico brillante (studs, puños, pomos de hombro).
void drawPlasticSphere(Canvas canvas, Offset center, double r, Color color) {
  final rect = Rect.fromCircle(center: center, radius: r);
  canvas.drawCircle(
    center,
    r,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.40),
        colors: [lightenColor(color, 0.16), color, darkenColor(color, 0.16)],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect),
  );
  canvas.drawCircle(
    Offset(center.dx - r * 0.30, center.dy - r * 0.36),
    r * 0.24,
    Paint()..color = Colors.white.withValues(alpha: 0.55),
  );
  canvas.drawCircle(
      center, r, outlinePaintFor(color, width: (r * 0.14).clamp(0.8, 1.4)));
}

/// Camino relleno con el mismo acabado de plástico (capas, faldas, alas).
void drawShadedPath(Canvas canvas, Path path, Color color,
    {double outlineWidth = 1.3}) {
  final bounds = path.getBounds();
  canvas.drawPath(
    path,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lightenColor(color, 0.08), color, darkenColor(color, 0.14)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(bounds.isEmpty ? const Rect.fromLTWH(0, 0, 1, 1) : bounds),
  );
  canvas.drawPath(path, outlinePaintFor(color, width: outlineWidth));
}

/// Pintura metálica pulida (espadas, armaduras, hebillas).
Paint metalPaint(Rect rect) => Paint()
  ..shader = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Colors.blueGrey.shade400,
      Colors.grey.shade100,
      Colors.blueGrey.shade300,
    ],
    stops: const [0.0, 0.45, 1.0],
  ).createShader(rect);

/// Sombra de contacto suave entre piezas (oclusión ambiental barata).
void drawContactShadow(Canvas canvas, Rect rect) {
  canvas.drawOval(
      rect, Paint()..color = Colors.black.withValues(alpha: 0.12));
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
