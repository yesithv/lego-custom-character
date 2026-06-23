import 'package:flutter/material.dart';

import '../../domain/entities/character.dart';

/// Renders the minifigure as layered colored blocks.
/// Each layer will eventually use PNG/SVG sprites; for now uses colored
/// rectangles so the composition pipeline is testable before art assets arrive.
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

    // Proportions based on LEGO minifigure ratio
    final headSize = w * 0.55;
    final headTop = h * 0.02;
    final torsoH = h * 0.28;
    final torsoTop = headTop + headSize + h * 0.02;
    final legH = h * 0.3;
    final legTop = torsoTop + torsoH;

    // Head
    _drawRoundRect(canvas, Rect.fromLTWH((w - headSize) / 2, headTop, headSize, headSize),
        skinColor, 8);

    // Eyes
    _drawEyes(canvas, (w - headSize) / 2, headTop, headSize);

    // Mouth
    _drawMouth(canvas, (w - headSize) / 2, headTop, headSize);

    // Hair/headwear
    if (appearance.headwearType == HeadwearType.hair) {
      _drawHair(canvas, (w - headSize) / 2, headTop, headSize);
    }

    // Torso
    final torsoColor = _torsoColor(appearance.torso);
    _drawRoundRect(
        canvas,
        Rect.fromLTWH((w - w * 0.7) / 2, torsoTop, w * 0.7, torsoH),
        torsoColor,
        6);

    // Legs
    final legColor = _legColor(appearance.legDesign);
    final legW = w * 0.3;
    _drawRoundRect(canvas,
        Rect.fromLTWH((w - legW * 2 - 4) / 2, legTop, legW, legH),
        legColor, 4);
    _drawRoundRect(canvas,
        Rect.fromLTWH((w + 4) / 2, legTop, legW, legH),
        legColor, 4);

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
    // LEGO stud border
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawEyes(Canvas canvas, double hx, double hy, double hs) {
    final eyeColor = appearance.eyes == EyeStyle.laser
        ? Colors.red
        : appearance.eyes == EyeStyle.robot
            ? Colors.cyan
            : Colors.black87;
    final eyeR = hs * 0.1;
    canvas.drawCircle(Offset(hx + hs * 0.3, hy + hs * 0.45), eyeR,
        Paint()..color = eyeColor);
    canvas.drawCircle(Offset(hx + hs * 0.7, hy + hs * 0.45), eyeR,
        Paint()..color = eyeColor);
    if (appearance.eyes == EyeStyle.starry) {
      canvas.drawCircle(Offset(hx + hs * 0.3, hy + hs * 0.45), eyeR * 1.5,
          Paint()..color = Colors.yellow.withValues(alpha: 0.5));
      canvas.drawCircle(Offset(hx + hs * 0.7, hy + hs * 0.45), eyeR * 1.5,
          Paint()..color = Colors.yellow.withValues(alpha: 0.5));
    }
  }

  void _drawMouth(Canvas canvas, double hx, double hy, double hs) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    switch (appearance.mouth) {
      case MouthStyle.smile:
        final path = Path()
          ..moveTo(hx + hs * 0.3, hy + hs * 0.65)
          ..quadraticBezierTo(
              hx + hs * 0.5, hy + hs * 0.78, hx + hs * 0.7, hy + hs * 0.65);
        canvas.drawPath(path, paint);
      case MouthStyle.frown:
        final path = Path()
          ..moveTo(hx + hs * 0.3, hy + hs * 0.75)
          ..quadraticBezierTo(
              hx + hs * 0.5, hy + hs * 0.63, hx + hs * 0.7, hy + hs * 0.75);
        canvas.drawPath(path, paint);
      default:
        canvas.drawLine(Offset(hx + hs * 0.35, hy + hs * 0.7),
            Offset(hx + hs * 0.65, hy + hs * 0.7), paint);
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
    ];
    final hairColor = hairColors[appearance.hairStyle?.index ?? 0 % hairColors.length];
    _drawRoundRect(canvas,
        Rect.fromLTWH(hx - 2, hy - hs * 0.12, hs + 4, hs * 0.35),
        hairColor, 6);
  }

  Color _skinColor(SkinTone tone) => switch (tone) {
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

  Color _torsoColor(TorsoDesign design) => switch (design) {
        TorsoDesign.plain => Colors.red.shade400,
        TorsoDesign.police => Colors.blue.shade800,
        TorsoDesign.firefighter => Colors.red.shade800,
        TorsoDesign.astronaut => Colors.grey.shade300,
        TorsoDesign.doctor => Colors.white,
        TorsoDesign.ninja => Colors.black,
        TorsoDesign.pirate => Colors.brown.shade700,
        TorsoDesign.superhero => Colors.blue.shade600,
        TorsoDesign.medieval => Colors.grey.shade600,
        TorsoDesign.robot => Colors.blueGrey.shade400,
        _ => Colors.teal.shade400,
      };

  Color _legColor(LegDesign design) => switch (design) {
        LegDesign.plain => Colors.blue.shade700,
        LegDesign.camouflage => Colors.green.shade700,
        LegDesign.armor => Colors.grey.shade600,
        LegDesign.flames => Colors.orange.shade700,
        _ => Colors.indigo.shade600,
      };

  Color _shoeColor(ShoeType shoe) => switch (shoe) {
        ShoeType.sneakers => Colors.white,
        ShoeType.military => Colors.brown.shade800,
        ShoeType.cowboy => Colors.brown.shade600,
        ShoeType.witchBoots => Colors.black,
        ShoeType.skates => Colors.grey.shade300,
        _ => Colors.grey.shade800,
      };

  @override
  bool shouldRepaint(_CharacterPainter oldDelegate) =>
      oldDelegate.appearance != appearance;
}
