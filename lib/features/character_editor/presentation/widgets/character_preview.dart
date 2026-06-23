import 'package:flutter/material.dart';

import '../../domain/entities/character.dart';

/// Renders the minifigure as layered colored blocks.
class CharacterPreview extends StatelessWidget {
  final CharacterAppearance appearance;
  final double size;

  const CharacterPreview({
    super.key,
    required this.appearance,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.6,
      child: CustomPaint(
        painter: _CharacterPainter(appearance),
      ),
    );
  }
}

class _CharacterPainter extends CustomPainter {
  final CharacterAppearance appearance;

  _CharacterPainter(this.appearance);

  @override
  void paint(Canvas canvas, Size size) {
    final skinColor = _skinColor(appearance.skinTone);
    final w = size.width;
    final h = size.height;

    final headSize = w * 0.55;
    final headTop = h * 0.02;
    final torsoH = h * 0.28;
    final torsoTop = headTop + headSize + h * 0.02;
    final legH = h * 0.3;
    final legTop = torsoTop + torsoH;
    final hx = (w - headSize) / 2;

    // Head
    _drawRoundRect(canvas, Rect.fromLTWH(hx, headTop, headSize, headSize), skinColor, 8);

    // Eyes
    _drawEyes(canvas, hx, headTop, headSize, skinColor);

    // Mouth
    _drawMouth(canvas, hx, headTop, headSize);

    // Headwear (hair / helmet / hat)
    if (appearance.headwearType == HeadwearType.hair) {
      _drawHair(canvas, hx, headTop, headSize);
    } else if (appearance.headwearType == HeadwearType.helmet) {
      _drawHelmet(canvas, hx, headTop, headSize);
    } else if (appearance.headwearType == HeadwearType.hat) {
      _drawHat(canvas, hx, headTop, headSize);
    }

    // Torso
    final torsoColor = _torsoColor(appearance.torso);
    final torsoX = (w - w * 0.7) / 2;
    _drawRoundRect(
        canvas,
        Rect.fromLTWH(torsoX, torsoTop, w * 0.7, torsoH),
        torsoColor,
        6);

    // Arms
    final armW = w * 0.12;
    final armH = h * 0.22;
    _drawRoundRect(canvas, Rect.fromLTWH(torsoX - armW, torsoTop + h * 0.02, armW, armH), skinColor, 4);
    _drawRoundRect(canvas, Rect.fromLTWH(torsoX + w * 0.7, torsoTop + h * 0.02, armW, armH), skinColor, 4);

    // Legs
    final legColor = _legColor(appearance.legDesign);
    final legW = w * 0.3;
    _drawRoundRect(canvas,
        Rect.fromLTWH((w - legW * 2 - 4) / 2, legTop, legW, legH), legColor, 4);
    _drawRoundRect(canvas,
        Rect.fromLTWH((w + 4) / 2, legTop, legW, legH), legColor, 4);

    // Shoes
    final shoeColor = _shoeColor(appearance.shoes);
    final shoeH = h * 0.08;
    _drawRoundRect(canvas,
        Rect.fromLTWH((w - legW * 2 - 4) / 2, legTop + legH - 4, legW, shoeH),
        shoeColor, 4);
    _drawRoundRect(canvas,
        Rect.fromLTWH((w + 4) / 2, legTop + legH - 4, legW, shoeH),
        shoeColor, 4);
  }

  void _drawRoundRect(Canvas canvas, Rect rect, Color color, double radius) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()..color = color,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawEyes(Canvas canvas, double hx, double hy, double hs, Color skinColor) {
    final eyeR = hs * 0.1;
    final eyeLX = hx + hs * 0.3;
    final eyeRX = hx + hs * 0.7;
    final eyeY = hy + hs * 0.45;
    final blackPaint = Paint()..color = Colors.black87;
    final strokePaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    if (appearance.eyes == EyeStyle.laser) {
      canvas.drawCircle(Offset(eyeLX, eyeY), eyeR, Paint()..color = Colors.red);
      canvas.drawCircle(Offset(eyeRX, eyeY), eyeR, Paint()..color = Colors.red);
    } else if (appearance.eyes == EyeStyle.robot) {
      final p = Paint()..color = Colors.cyan;
      canvas.drawRect(Rect.fromCenter(center: Offset(eyeLX, eyeY), width: eyeR * 2.2, height: eyeR * 1.4), p);
      canvas.drawRect(Rect.fromCenter(center: Offset(eyeRX, eyeY), width: eyeR * 2.2, height: eyeR * 1.4), p);
    } else if (appearance.eyes == EyeStyle.starry) {
      canvas.drawCircle(Offset(eyeLX, eyeY), eyeR * 1.5, Paint()..color = Colors.yellow.withValues(alpha: 0.5));
      canvas.drawCircle(Offset(eyeRX, eyeY), eyeR * 1.5, Paint()..color = Colors.yellow.withValues(alpha: 0.5));
      canvas.drawCircle(Offset(eyeLX, eyeY), eyeR, blackPaint);
      canvas.drawCircle(Offset(eyeRX, eyeY), eyeR, blackPaint);
    } else if (appearance.eyes == EyeStyle.surprised) {
      canvas.drawCircle(Offset(eyeLX, eyeY), eyeR * 1.5, blackPaint);
      canvas.drawCircle(Offset(eyeRX, eyeY), eyeR * 1.5, blackPaint);
    } else if (appearance.eyes == EyeStyle.angry) {
      canvas.drawCircle(Offset(eyeLX, eyeY), eyeR, blackPaint);
      canvas.drawCircle(Offset(eyeRX, eyeY), eyeR, blackPaint);
      // Angry V-shaped brows
      canvas.drawLine(Offset(eyeLX - eyeR, eyeY - eyeR * 1.8), Offset(eyeLX + eyeR, eyeY - eyeR * 2.8), strokePaint);
      canvas.drawLine(Offset(eyeRX - eyeR, eyeY - eyeR * 2.8), Offset(eyeRX + eyeR, eyeY - eyeR * 1.8), strokePaint);
    } else if (appearance.eyes == EyeStyle.sleepy) {
      canvas.drawCircle(Offset(eyeLX, eyeY), eyeR, blackPaint);
      canvas.drawCircle(Offset(eyeRX, eyeY), eyeR, blackPaint);
      // Half-closed: cover top half with skin color
      final coverPaint = Paint()..color = skinColor;
      canvas.drawRect(Rect.fromLTWH(eyeLX - eyeR * 1.3, eyeY - eyeR * 1.5, eyeR * 2.6, eyeR * 1.3), coverPaint);
      canvas.drawRect(Rect.fromLTWH(eyeRX - eyeR * 1.3, eyeY - eyeR * 1.5, eyeR * 2.6, eyeR * 1.3), coverPaint);
      // Eyelid line
      canvas.drawLine(Offset(eyeLX - eyeR, eyeY - eyeR * 0.2), Offset(eyeLX + eyeR, eyeY - eyeR * 0.2), strokePaint);
      canvas.drawLine(Offset(eyeRX - eyeR, eyeY - eyeR * 0.2), Offset(eyeRX + eyeR, eyeY - eyeR * 0.2), strokePaint);
    } else if (appearance.eyes == EyeStyle.wink) {
      canvas.drawCircle(Offset(eyeLX, eyeY), eyeR, blackPaint);
      // Right eye winked (curved line)
      final winkPath = Path()
        ..moveTo(eyeRX - eyeR, eyeY)
        ..quadraticBezierTo(eyeRX, eyeY - eyeR * 0.8, eyeRX + eyeR, eyeY);
      canvas.drawPath(winkPath, strokePaint);
    } else if (appearance.eyes == EyeStyle.crying) {
      canvas.drawCircle(Offset(eyeLX, eyeY), eyeR, blackPaint);
      canvas.drawCircle(Offset(eyeRX, eyeY), eyeR, blackPaint);
      // Tears
      final tearPaint = Paint()..color = Colors.lightBlue.shade300;
      canvas.drawOval(Rect.fromCenter(center: Offset(eyeLX - eyeR * 0.2, eyeY + eyeR * 2.5), width: eyeR * 0.7, height: eyeR * 1.8), tearPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(eyeRX + eyeR * 0.2, eyeY + eyeR * 2.5), width: eyeR * 0.7, height: eyeR * 1.8), tearPaint);
    } else {
      // happy — default
      canvas.drawCircle(Offset(eyeLX, eyeY), eyeR, blackPaint);
      canvas.drawCircle(Offset(eyeRX, eyeY), eyeR, blackPaint);
    }
  }

  void _drawMouth(Canvas canvas, double hx, double hy, double hs) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    if (appearance.mouth == MouthStyle.smile) {
      final path = Path()
        ..moveTo(hx + hs * 0.3, hy + hs * 0.65)
        ..quadraticBezierTo(hx + hs * 0.5, hy + hs * 0.78, hx + hs * 0.7, hy + hs * 0.65);
      canvas.drawPath(path, paint);
    } else if (appearance.mouth == MouthStyle.frown) {
      final path = Path()
        ..moveTo(hx + hs * 0.3, hy + hs * 0.75)
        ..quadraticBezierTo(hx + hs * 0.5, hy + hs * 0.63, hx + hs * 0.7, hy + hs * 0.75);
      canvas.drawPath(path, paint);
    } else if (appearance.mouth == MouthStyle.teeth) {
      // Open mouth filled white with a teeth divider
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(hx + hs * 0.28, hy + hs * 0.64, hs * 0.44, hs * 0.13), const Radius.circular(3)),
        Paint()..color = Colors.white,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(hx + hs * 0.28, hy + hs * 0.64, hs * 0.44, hs * 0.13), const Radius.circular(3)),
        paint,
      );
      canvas.drawLine(Offset(hx + hs * 0.5, hy + hs * 0.64), Offset(hx + hs * 0.5, hy + hs * 0.77), paint);
    } else if (appearance.mouth == MouthStyle.fangs) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(hx + hs * 0.28, hy + hs * 0.64, hs * 0.44, hs * 0.13), const Radius.circular(3)),
        Paint()..color = Colors.white,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(hx + hs * 0.28, hy + hs * 0.64, hs * 0.44, hs * 0.13), const Radius.circular(3)),
        paint,
      );
      // Fangs
      final fangPath = Path()
        ..moveTo(hx + hs * 0.35, hy + hs * 0.64)
        ..lineTo(hx + hs * 0.385, hy + hs * 0.73)
        ..lineTo(hx + hs * 0.42, hy + hs * 0.64)
        ..moveTo(hx + hs * 0.58, hy + hs * 0.64)
        ..lineTo(hx + hs * 0.615, hy + hs * 0.73)
        ..lineTo(hx + hs * 0.65, hy + hs * 0.64);
      canvas.drawPath(fangPath, Paint()..color = Colors.white..style = PaintingStyle.fill);
      canvas.drawPath(fangPath, paint);
    } else if (appearance.mouth == MouthStyle.mustache) {
      canvas.drawLine(Offset(hx + hs * 0.35, hy + hs * 0.7), Offset(hx + hs * 0.65, hy + hs * 0.7), paint);
      final mustache = Path()
        ..moveTo(hx + hs * 0.28, hy + hs * 0.63)
        ..cubicTo(hx + hs * 0.35, hy + hs * 0.57, hx + hs * 0.45, hy + hs * 0.60, hx + hs * 0.5, hy + hs * 0.63)
        ..cubicTo(hx + hs * 0.55, hy + hs * 0.60, hx + hs * 0.65, hy + hs * 0.57, hx + hs * 0.72, hy + hs * 0.63);
      canvas.drawPath(mustache, paint);
    } else if (appearance.mouth == MouthStyle.tongueOut) {
      final smilePath = Path()
        ..moveTo(hx + hs * 0.3, hy + hs * 0.65)
        ..quadraticBezierTo(hx + hs * 0.5, hy + hs * 0.78, hx + hs * 0.7, hy + hs * 0.65);
      canvas.drawPath(smilePath, paint);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(hx + hs * 0.5, hy + hs * 0.79), width: hs * 0.18, height: hs * 0.13),
        Paint()..color = Colors.pink.shade400,
      );
    } else {
      // silent / default — flat line
      canvas.drawLine(Offset(hx + hs * 0.35, hy + hs * 0.7), Offset(hx + hs * 0.65, hy + hs * 0.7), paint);
    }
  }

  void _drawHair(Canvas canvas, double hx, double hy, double hs) {
    final hairColors = [
      Colors.brown.shade700,
      Colors.black,
      Colors.amber,
      Colors.orange,
      Colors.red.shade700,
      Colors.grey.shade300,
      Colors.yellow.shade200,
      Colors.grey.shade800,
    ];
    final hairColor = hairColors[(appearance.hairStyle?.index ?? 0) % hairColors.length];
    _drawRoundRect(canvas, Rect.fromLTWH(hx - 2, hy - hs * 0.12, hs + 4, hs * 0.35), hairColor, 6);
  }

  void _drawHelmet(Canvas canvas, double hx, double hy, double hs) {
    final style = appearance.helmetStyle ?? HelmetStyle.medieval;
    Color color;
    if (style == HelmetStyle.space || style == HelmetStyle.astronaut) {
      color = Colors.white;
    } else if (style == HelmetStyle.firefighter) {
      color = Colors.yellow.shade700;
    } else if (style == HelmetStyle.biker) {
      color = Colors.black;
    } else if (style == HelmetStyle.roman) {
      color = Colors.red.shade700;
    } else if (style == HelmetStyle.viking) {
      color = Colors.grey.shade400;
    } else {
      color = Colors.grey.shade600; // medieval default
    }
    // Dome
    _drawRoundRect(canvas, Rect.fromLTWH(hx - 3, hy - hs * 0.15, hs + 6, hs * 0.5), color, 10);
    // Visor
    canvas.drawRect(
      Rect.fromLTWH(hx + hs * 0.15, hy + hs * 0.2, hs * 0.7, hs * 0.12),
      Paint()..color = Colors.lightBlue.withValues(alpha: 0.5),
    );
  }

  void _drawHat(Canvas canvas, double hx, double hy, double hs) {
    final style = appearance.hatStyle ?? HatStyle.cap;
    Color brimColor;
    Color topColor;
    if (style == HatStyle.wizard) {
      brimColor = Colors.indigo.shade800;
      topColor = Colors.indigo.shade700;
    } else if (style == HatStyle.cowboy) {
      brimColor = Colors.brown.shade600;
      topColor = Colors.brown.shade500;
    } else if (style == HatStyle.crown || style == HatStyle.tiara) {
      brimColor = const Color(0xFFFFD700);
      topColor = const Color(0xFFFFD700);
    } else if (style == HatStyle.topHat) {
      brimColor = Colors.black;
      topColor = Colors.black;
    } else if (style == HatStyle.pirate) {
      brimColor = Colors.black;
      topColor = Colors.black;
    } else {
      brimColor = Colors.red.shade600; // cap
      topColor = Colors.red.shade500;
    }
    // Brim
    _drawRoundRect(canvas, Rect.fromLTWH(hx - hs * 0.1, hy + hs * 0.02, hs * 1.2, hs * 0.12), brimColor, 3);
    // Top
    if (style == HatStyle.wizard) {
      final path = Path()
        ..moveTo(hx + hs * 0.1, hy + hs * 0.04)
        ..lineTo(hx + hs * 0.5, hy - hs * 0.45)
        ..lineTo(hx + hs * 0.9, hy + hs * 0.04)
        ..close();
      canvas.drawPath(path, Paint()..color = topColor);
    } else if (style == HatStyle.crown || style == HatStyle.tiara) {
      final path = Path()
        ..moveTo(hx + hs * 0.15, hy + hs * 0.02)
        ..lineTo(hx + hs * 0.15, hy - hs * 0.22)
        ..lineTo(hx + hs * 0.3, hy - hs * 0.1)
        ..lineTo(hx + hs * 0.5, hy - hs * 0.28)
        ..lineTo(hx + hs * 0.7, hy - hs * 0.1)
        ..lineTo(hx + hs * 0.85, hy - hs * 0.22)
        ..lineTo(hx + hs * 0.85, hy + hs * 0.02)
        ..close();
      canvas.drawPath(path, Paint()..color = topColor);
    } else {
      _drawRoundRect(canvas, Rect.fromLTWH(hx + hs * 0.05, hy - hs * 0.25, hs * 0.9, hs * 0.3), topColor, 4);
    }
  }

  Color _skinColor(SkinTone tone) {
    if (tone == SkinTone.light) return const Color(0xFFFFDBAC);
    if (tone == SkinTone.medium) return const Color(0xFFD4A574);
    if (tone == SkinTone.dark) return const Color(0xFF8D5524);
    if (tone == SkinTone.blue) return Colors.blue.shade400;
    if (tone == SkinTone.green) return Colors.green.shade400;
    if (tone == SkinTone.purple) return Colors.purple.shade400;
    if (tone == SkinTone.orange) return Colors.orange.shade400;
    if (tone == SkinTone.silver) return Colors.grey.shade400;
    return const Color(0xFFFFD700);
  }

  Color _torsoColor(TorsoDesign design) {
    if (design == TorsoDesign.plain) return Colors.red.shade400;
    if (design == TorsoDesign.police) return Colors.blue.shade800;
    if (design == TorsoDesign.firefighter) return Colors.red.shade800;
    if (design == TorsoDesign.astronaut) return Colors.grey.shade300;
    if (design == TorsoDesign.doctor) return Colors.white;
    if (design == TorsoDesign.ninja) return Colors.black;
    if (design == TorsoDesign.pirate) return Colors.brown.shade700;
    if (design == TorsoDesign.superhero) return Colors.blue.shade600;
    if (design == TorsoDesign.medieval) return Colors.grey.shade600;
    if (design == TorsoDesign.robot) return Colors.blueGrey.shade400;
    return Colors.teal.shade400;
  }

  Color _legColor(LegDesign design) {
    if (design == LegDesign.plain) return Colors.blue.shade700;
    if (design == LegDesign.camouflage) return Colors.green.shade700;
    if (design == LegDesign.armor) return Colors.grey.shade600;
    if (design == LegDesign.flames) return Colors.orange.shade700;
    return Colors.indigo.shade600;
  }

  Color _shoeColor(ShoeType shoe) {
    if (shoe == ShoeType.sneakers) return Colors.white;
    if (shoe == ShoeType.military) return Colors.brown.shade800;
    if (shoe == ShoeType.cowboy) return Colors.brown.shade600;
    if (shoe == ShoeType.witchBoots) return Colors.black;
    if (shoe == ShoeType.skates) return Colors.grey.shade300;
    return Colors.grey.shade800;
  }

  @override
  bool shouldRepaint(_CharacterPainter oldDelegate) =>
      oldDelegate.appearance != appearance;
}
