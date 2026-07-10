import 'package:flutter/material.dart';

import '../../domain/entities/character.dart';
import 'appearance_colors.dart';

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

  // Layout (computed once per paint)
  late double w, h;
  late double headSize, headTop, hx;
  late double neckTop, neckH;
  late double torsoX, torsoTop, torsoW, torsoH;
  late double armW, armH, armTop;
  late double fistR;
  late Offset leftFist, rightFist;
  late double hipTop, hipW, hipH;
  late double legTop, legW, legH, leftLegX, rightLegX;
  late double shoeTop, shoeW, shoeH, shoeOffset;
  late Color skin, torsoColor, legColor, shoeColor;

  @override
  void paint(Canvas canvas, Size size) {
    w = size.width;
    h = size.height;
    skin = skinColorFor(appearance.skinTone);
    torsoColor = torsoColorFor(appearance.torso);
    legColor = legColorFor(appearance.legDesign);
    shoeColor = shoeColorFor(appearance.shoes, skin);

    headSize = w * 0.50;
    headTop = h * 0.04;
    hx = (w - headSize) / 2;
    neckTop = headTop + headSize;
    neckH = h * 0.03;
    torsoW = w * 0.62;
    torsoH = h * 0.22;
    torsoTop = neckTop + neckH;
    torsoX = (w - torsoW) / 2;
    armW = w * 0.12;
    armH = h * 0.17;
    armTop = torsoTop + h * 0.01;
    fistR = armW * 0.55;
    leftFist = Offset(torsoX - armW / 2, armTop + armH + fistR * 0.55);
    rightFist = Offset(torsoX + torsoW + armW / 2, armTop + armH + fistR * 0.55);
    hipW = w * 0.64;
    hipH = h * 0.07;
    hipTop = torsoTop + torsoH;
    legW = w * 0.28;
    legH = h * 0.25;
    legTop = hipTop + hipH;
    final legGap = w * 0.04;
    leftLegX = (w - legW * 2 - legGap) / 2;
    rightLegX = leftLegX + legW + legGap;
    shoeW = w * 0.32;
    shoeH = h * 0.09;
    shoeOffset = (shoeW - legW) / 2;
    shoeTop = legTop + legH - h * 0.02;

    // Behind the body
    _drawBackAccessory(canvas);
    if (appearance.hasCape) _drawLongCape(canvas);

    // Head
    _drawHeadBlock(canvas);
    _drawEyes(canvas, hx, headTop, headSize, skin);
    _drawMouth(canvas, hx, headTop, headSize);
    _drawHeadwear(canvas);
    _drawFaceAccessory(canvas);

    // Torso + arms
    _drawNeckAndTorso(canvas);
    _drawArmsAndHands(canvas);
    _drawShoulderAccessory(canvas);
    _drawNeckAccessory(canvas);

    // Hips + legs + shoes
    _drawHipsAndLegs(canvas);
    _drawWaistAccessory(canvas);
    _drawShoes(canvas);
    _drawFeetAccessory(canvas);

    // Held items in front of everything
    _drawHandAccessory(canvas, appearance.accessories.rightHand, rightFist);
    _drawHandAccessory(canvas, appearance.accessories.leftHand, leftFist);
  }

  // ── Body blocks ─────────────────────────────────────────────────────────────

  void _drawHeadBlock(Canvas canvas) {
    // Stud on top of head (drawn first — head rect covers its lower half)
    final studR = headSize * 0.16;
    canvas.drawCircle(Offset(w / 2, headTop - studR * 0.35), studR, Paint()..color = skin);
    canvas.drawCircle(
      Offset(w / 2, headTop - studR * 0.35),
      studR,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    _drawRoundRect(canvas, Rect.fromLTWH(hx, headTop, headSize, headSize), skin, 8);
  }

  void _drawNeckAndTorso(Canvas canvas) {
    final neckW = headSize * 0.30;
    _drawRoundRect(canvas, Rect.fromLTWH((w - neckW) / 2, neckTop, neckW, neckH), skin, 3);
    _drawRoundRect(canvas, Rect.fromLTWH(torsoX, torsoTop, torsoW, torsoH), torsoColor, 6);
    _drawTorsoDetail(canvas);
  }

  void _drawArmsAndHands(Canvas canvas) {
    _drawRoundRect(canvas, Rect.fromLTWH(torsoX - armW, armTop, armW, armH), skin, 4);
    _drawRoundRect(canvas, Rect.fromLTWH(torsoX + torsoW, armTop, armW, armH), skin, 4);

    // Shoulder knobs (torso color, at arm-torso junction)
    final knobR = armW * 0.55;
    canvas.drawCircle(Offset(torsoX, armTop + knobR), knobR, Paint()..color = torsoColor);
    canvas.drawCircle(Offset(torsoX + torsoW, armTop + knobR), knobR, Paint()..color = torsoColor);

    // Fists — colored by glove type
    final gloveColor = gloveColorFor(appearance.gloves, skin);
    final r = appearance.gloves == GloveType.boxing ? fistR * 1.35 : fistR;
    canvas.drawCircle(leftFist, r, Paint()..color = gloveColor);
    canvas.drawCircle(rightFist, r, Paint()..color = gloveColor);
    if (appearance.gloves == GloveType.claws) {
      final clawPaint = Paint()
        ..color = Colors.grey.shade100
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      for (final fist in [leftFist, rightFist]) {
        for (var i = -1; i <= 1; i++) {
          canvas.drawLine(
            Offset(fist.dx + i * fistR * 0.5, fist.dy + fistR * 0.4),
            Offset(fist.dx + i * fistR * 0.7, fist.dy + fistR * 1.3),
            clawPaint,
          );
        }
      }
    } else if (appearance.gloves == GloveType.medieval) {
      // Plate line across the gauntlet
      final line = Paint()
        ..color = Colors.grey.shade700
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      canvas.drawLine(Offset(leftFist.dx - fistR * 0.7, leftFist.dy),
          Offset(leftFist.dx + fistR * 0.7, leftFist.dy), line);
      canvas.drawLine(Offset(rightFist.dx - fistR * 0.7, rightFist.dy),
          Offset(rightFist.dx + fistR * 0.7, rightFist.dy), line);
    }
  }

  void _drawHipsAndLegs(Canvas canvas) {
    final legType = appearance.legType;
    final hipColor = legType == LegType.spacesuit ? Colors.white : legColor;
    _drawRoundRect(canvas, Rect.fromLTWH((w - hipW) / 2, hipTop, hipW, hipH), hipColor, 4);

    final leftRect = Rect.fromLTWH(leftLegX, legTop, legW, legH);
    final rightRect = Rect.fromLTWH(rightLegX, legTop, legW, legH);

    switch (legType) {
      case LegType.pants:
        _drawPatternedLeg(canvas, leftRect);
        _drawPatternedLeg(canvas, rightRect);

      case LegType.shorts:
        // Bare lower legs, patterned shorts on top
        _drawRoundRect(canvas, leftRect, skin, 4);
        _drawRoundRect(canvas, rightRect, skin, 4);
        _drawPatternedLeg(
            canvas, Rect.fromLTWH(leftLegX, legTop, legW, legH * 0.48));
        _drawPatternedLeg(
            canvas, Rect.fromLTWH(rightLegX, legTop, legW, legH * 0.48));

      case LegType.skirt:
        _drawRoundRect(canvas, leftRect, skin, 4);
        _drawRoundRect(canvas, rightRect, skin, 4);
        final skirt = Path()
          ..moveTo((w - hipW) / 2, hipTop)
          ..lineTo((w + hipW) / 2, hipTop)
          ..lineTo((w + hipW) / 2 + w * 0.05, legTop + legH * 0.40)
          ..lineTo((w - hipW) / 2 - w * 0.05, legTop + legH * 0.40)
          ..close();
        canvas.drawPath(skirt, Paint()..color = legColor);

      case LegType.legArmor:
        _drawPatternedLeg(canvas, leftRect);
        _drawPatternedLeg(canvas, rightRect);
        final plate = Paint()..color = Colors.grey.shade500;
        // Knee pads + shin plates
        for (final x in [leftLegX, rightLegX]) {
          canvas.drawCircle(
              Offset(x + legW / 2, legTop + legH * 0.42), legW * 0.28, plate);
          _drawRoundRect(
              canvas,
              Rect.fromLTWH(x + legW * 0.15, legTop + legH * 0.58,
                  legW * 0.7, legH * 0.32),
              Colors.grey.shade500,
              3);
        }

      case LegType.spacesuit:
        // Puffy white suit with colored thigh bands
        _drawRoundRect(canvas, leftRect.inflate(1.5), Colors.white, 6);
        _drawRoundRect(canvas, rightRect.inflate(1.5), Colors.white, 6);
        final band = Paint()..color = legColor;
        for (final x in [leftLegX, rightLegX]) {
          canvas.drawRect(
              Rect.fromLTWH(x, legTop + legH * 0.25, legW, legH * 0.10), band);
          canvas.drawRect(
              Rect.fromLTWH(x, legTop + legH * 0.70, legW, legH * 0.10), band);
        }
    }
  }

  void _drawPatternedLeg(Canvas canvas, Rect rect) {
    _drawRoundRect(canvas, rect, legColor, 4);
    paintLegPattern(canvas, rect, appearance.legDesign);
  }

  void _drawShoes(Canvas canvas) {
    final leftRect =
        Rect.fromLTWH(leftLegX - shoeOffset, shoeTop, shoeW, shoeH);
    final rightRect =
        Rect.fromLTWH(rightLegX - shoeOffset, shoeTop, shoeW, shoeH);
    _drawShoe(canvas, leftRect, isLeft: true);
    _drawShoe(canvas, rightRect, isLeft: false);
  }

  void _drawShoe(Canvas canvas, Rect rect, {required bool isLeft}) {
    switch (appearance.shoes) {
      case ShoeType.sneakers:
        _drawRoundRect(canvas, rect, Colors.white, 3);
        canvas.drawRect(
            Rect.fromLTWH(rect.left, rect.bottom - rect.height * 0.3,
                rect.width, rect.height * 0.3),
            Paint()..color = Colors.grey.shade400);
      case ShoeType.military:
        _drawRoundRect(canvas, rect, Colors.brown.shade800, 3);
        canvas.drawRect(
            Rect.fromLTWH(rect.left, rect.bottom - rect.height * 0.25,
                rect.width, rect.height * 0.25),
            Paint()..color = Colors.black87);
      case ShoeType.cowboy:
        _drawRoundRect(canvas, rect, Colors.brown.shade600, 3);
        // Pointed toe extending outwards
        final tipX = isLeft ? rect.left - rect.width * 0.18 : rect.right + rect.width * 0.18;
        final path = Path()
          ..moveTo(isLeft ? rect.left : rect.right, rect.top + rect.height * 0.35)
          ..lineTo(tipX, rect.bottom)
          ..lineTo(isLeft ? rect.left : rect.right, rect.bottom)
          ..close();
        canvas.drawPath(path, Paint()..color = Colors.brown.shade600);
      case ShoeType.sandals:
        _drawRoundRect(canvas, rect, skin, 3);
        final strap = Paint()..color = Colors.brown.shade500;
        canvas.drawRect(
            Rect.fromLTWH(rect.left, rect.top + rect.height * 0.2,
                rect.width, rect.height * 0.2),
            strap);
        canvas.drawRect(
            Rect.fromLTWH(rect.left, rect.bottom - rect.height * 0.22,
                rect.width, rect.height * 0.18),
            strap);
      case ShoeType.skates:
        _drawRoundRect(
            canvas,
            Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.65),
            Colors.grey.shade300,
            3);
        final wheel = Paint()..color = Colors.black87;
        final wheelR = rect.height * 0.20;
        canvas.drawCircle(
            Offset(rect.left + rect.width * 0.28, rect.bottom - wheelR), wheelR, wheel);
        canvas.drawCircle(
            Offset(rect.left + rect.width * 0.72, rect.bottom - wheelR), wheelR, wheel);
      case ShoeType.flippers:
        // Long fins extending outwards
        final finRect = isLeft
            ? Rect.fromLTWH(rect.left - rect.width * 0.35, rect.top,
                rect.width * 1.35, rect.height)
            : Rect.fromLTWH(rect.left, rect.top, rect.width * 1.35, rect.height);
        _drawRoundRect(canvas, finRect, Colors.blue.shade600, 6);
      case ShoeType.witchBoots:
        _drawRoundRect(canvas, rect, Colors.black, 3);
        // Curled tip
        final tipX = isLeft ? rect.left : rect.right;
        canvas.drawCircle(Offset(tipX, rect.top + rect.height * 0.3),
            rect.height * 0.28, Paint()..color = Colors.black);
      case ShoeType.barefoot:
        _drawRoundRect(canvas, rect, skin, 5);
        final toe = Paint()
          ..color = Colors.black.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        final toeX = isLeft ? rect.left + rect.width * 0.2 : rect.right - rect.width * 0.2;
        canvas.drawLine(Offset(toeX, rect.top + rect.height * 0.25),
            Offset(toeX, rect.bottom - rect.height * 0.25), toe);
    }
  }

  // ── Torso detail per design ─────────────────────────────────────────────────

  void _drawTorsoDetail(Canvas canvas) {
    final cx = torsoX + torsoW / 2;
    switch (appearance.torso) {
      case TorsoDesign.plain:
      case TorsoDesign.casual:
        break;
      case TorsoDesign.police:
        canvas.drawCircle(Offset(torsoX + torsoW * 0.28, torsoTop + torsoH * 0.3),
            torsoW * 0.07, Paint()..color = const Color(0xFFFFD700));
      case TorsoDesign.firefighter:
        canvas.drawRect(
            Rect.fromLTWH(torsoX, torsoTop + torsoH * 0.42, torsoW, torsoH * 0.16),
            Paint()..color = Colors.yellow.shade600);
      case TorsoDesign.astronaut:
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: Offset(cx, torsoTop + torsoH * 0.4),
                    width: torsoW * 0.4,
                    height: torsoH * 0.3),
                const Radius.circular(3)),
            Paint()..color = Colors.blue.shade300);
        canvas.drawCircle(Offset(cx - torsoW * 0.08, torsoTop + torsoH * 0.72),
            2, Paint()..color = Colors.red);
        canvas.drawCircle(Offset(cx + torsoW * 0.08, torsoTop + torsoH * 0.72),
            2, Paint()..color = Colors.green);
      case TorsoDesign.doctor:
        final cross = Paint()..color = Colors.red.shade600;
        canvas.drawRect(
            Rect.fromCenter(
                center: Offset(cx, torsoTop + torsoH * 0.45),
                width: torsoW * 0.12,
                height: torsoH * 0.4),
            cross);
        canvas.drawRect(
            Rect.fromCenter(
                center: Offset(cx, torsoTop + torsoH * 0.45),
                width: torsoW * 0.34,
                height: torsoH * 0.14),
            cross);
      case TorsoDesign.chef:
        final button = Paint()..color = Colors.black87;
        for (var i = 0; i < 3; i++) {
          final y = torsoTop + torsoH * (0.25 + i * 0.25);
          canvas.drawCircle(Offset(cx - torsoW * 0.12, y), 2, button);
          canvas.drawCircle(Offset(cx + torsoW * 0.12, y), 2, button);
        }
      case TorsoDesign.military:
        final blotch = Paint()..color = Colors.green.shade900;
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(torsoX + torsoW * 0.3, torsoTop + torsoH * 0.3),
                width: torsoW * 0.3,
                height: torsoH * 0.18),
            blotch);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(torsoX + torsoW * 0.7, torsoTop + torsoH * 0.65),
                width: torsoW * 0.28,
                height: torsoH * 0.16),
            blotch);
      case TorsoDesign.ninja:
        canvas.drawRect(
            Rect.fromLTWH(torsoX, torsoTop + torsoH * 0.6, torsoW, torsoH * 0.16),
            Paint()..color = Colors.grey.shade800);
      case TorsoDesign.pirate:
        canvas.drawLine(
            Offset(torsoX + torsoW * 0.15, torsoTop + torsoH * 0.1),
            Offset(torsoX + torsoW * 0.85, torsoTop + torsoH * 0.9),
            Paint()
              ..color = Colors.grey.shade100
              ..strokeWidth = 4);
      case TorsoDesign.superhero:
        final diamond = Path()
          ..moveTo(cx, torsoTop + torsoH * 0.2)
          ..lineTo(cx + torsoW * 0.18, torsoTop + torsoH * 0.48)
          ..lineTo(cx, torsoTop + torsoH * 0.76)
          ..lineTo(cx - torsoW * 0.18, torsoTop + torsoH * 0.48)
          ..close();
        canvas.drawPath(diamond, Paint()..color = Colors.red.shade600);
        canvas.drawPath(
            diamond,
            Paint()
              ..color = Colors.yellow.shade600
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      case TorsoDesign.medieval:
        final line = Paint()
          ..color = Colors.grey.shade800
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawLine(Offset(torsoX, torsoTop + torsoH * 0.35),
            Offset(torsoX + torsoW, torsoTop + torsoH * 0.35), line);
        canvas.drawLine(Offset(torsoX, torsoTop + torsoH * 0.65),
            Offset(torsoX + torsoW, torsoTop + torsoH * 0.65), line);
      case TorsoDesign.futuristic:
        final glow = Paint()..color = Colors.cyan.shade200;
        canvas.drawRect(
            Rect.fromLTWH(torsoX + torsoW * 0.15, torsoTop + torsoH * 0.4,
                torsoW * 0.7, 2.5),
            glow);
        canvas.drawCircle(
            Offset(cx, torsoTop + torsoH * 0.62), torsoW * 0.06, glow);
      case TorsoDesign.samurai:
        final plate = Paint()
          ..color = Colors.black.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        for (var i = 1; i <= 3; i++) {
          final y = torsoTop + torsoH * i / 4;
          canvas.drawLine(Offset(torsoX, y), Offset(torsoX + torsoW, y), plate);
        }
      case TorsoDesign.dinosaur:
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(cx, torsoTop + torsoH * 0.6),
                width: torsoW * 0.45,
                height: torsoH * 0.55),
            Paint()..color = Colors.lightGreen.shade200);
      case TorsoDesign.robot:
        _drawRoundRect(
            canvas,
            Rect.fromCenter(
                center: Offset(cx, torsoTop + torsoH * 0.42),
                width: torsoW * 0.45,
                height: torsoH * 0.32),
            Colors.blueGrey.shade600,
            3);
        canvas.drawCircle(Offset(cx - torsoW * 0.08, torsoTop + torsoH * 0.72),
            2, Paint()..color = Colors.red);
        canvas.drawCircle(Offset(cx + torsoW * 0.08, torsoTop + torsoH * 0.72),
            2, Paint()..color = Colors.yellow);
      case TorsoDesign.monster:
        final fur = Paint()..color = Colors.purple.shade900;
        final path = Path()..moveTo(torsoX, torsoTop + torsoH);
        for (var i = 0; i < 4; i++) {
          path
            ..lineTo(torsoX + torsoW * (i + 0.5) / 4, torsoTop + torsoH * 0.72)
            ..lineTo(torsoX + torsoW * (i + 1) / 4, torsoTop + torsoH);
        }
        path.close();
        canvas.drawPath(path, fur);
      case TorsoDesign.alien:
        final dot = Paint()..color = Colors.lightGreen.shade900;
        canvas.drawCircle(Offset(torsoX + torsoW * 0.3, torsoTop + torsoH * 0.3), 2.5, dot);
        canvas.drawCircle(Offset(torsoX + torsoW * 0.65, torsoTop + torsoH * 0.5), 2.5, dot);
        canvas.drawCircle(Offset(torsoX + torsoW * 0.4, torsoTop + torsoH * 0.72), 2.5, dot);
    }
  }

  // ── Cape ────────────────────────────────────────────────────────────────────

  void _drawLongCape(Canvas canvas) {
    final capeColor = Colors.red.shade700;
    final path = Path()
      ..moveTo(torsoX - armW * 0.4, torsoTop)
      ..lineTo(torsoX + torsoW + armW * 0.4, torsoTop)
      ..lineTo(torsoX + torsoW + armW * 1.1, legTop + legH * 0.55)
      ..lineTo(torsoX - armW * 1.1, legTop + legH * 0.55)
      ..close();
    canvas.drawPath(path, Paint()..color = capeColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  // ── Accessories ─────────────────────────────────────────────────────────────

  void _drawBackAccessory(Canvas canvas) {
    final id = appearance.accessories.back;
    if (id == null) return;
    switch (id) {
      case 'capa corta':
        final path = Path()
          ..moveTo(torsoX - armW * 0.3, torsoTop)
          ..lineTo(torsoX + torsoW + armW * 0.3, torsoTop)
          ..lineTo(torsoX + torsoW + armW * 0.7, hipTop + hipH)
          ..lineTo(torsoX - armW * 0.7, hipTop + hipH)
          ..close();
        canvas.drawPath(path, Paint()..color = Colors.blue.shade800);
      case 'capa vampiro':
        final path = Path()
          ..moveTo(torsoX - armW * 0.5, torsoTop)
          ..lineTo(torsoX + torsoW + armW * 0.5, torsoTop)
          ..lineTo(torsoX + torsoW + armW * 1.3, legTop + legH * 0.5)
          ..lineTo(torsoX - armW * 1.3, legTop + legH * 0.5)
          ..close();
        canvas.drawPath(path, Paint()..color = Colors.grey.shade900);
        // High collar behind the head
        final collar = Paint()..color = Colors.grey.shade900;
        final collarL = Path()
          ..moveTo(hx - 2, neckTop)
          ..lineTo(hx - headSize * 0.14, headTop + headSize * 0.35)
          ..lineTo(hx + headSize * 0.12, neckTop)
          ..close();
        final collarR = Path()
          ..moveTo(hx + headSize + 2, neckTop)
          ..lineTo(hx + headSize + headSize * 0.14, headTop + headSize * 0.35)
          ..lineTo(hx + headSize - headSize * 0.12, neckTop)
          ..close();
        canvas.drawPath(collarL, collar);
        canvas.drawPath(collarR, collar);
      case 'mochila':
        _drawRoundRect(
            canvas,
            Rect.fromLTWH(torsoX - w * 0.05, torsoTop + torsoH * 0.08,
                torsoW + w * 0.10, torsoH * 0.75),
            Colors.green.shade800,
            8);
      case 'jetpack':
        final body = Colors.grey.shade600;
        final flame = Paint()..color = Colors.orange.shade600;
        for (final x in [torsoX - w * 0.055, torsoX + torsoW - w * 0.035]) {
          _drawRoundRect(canvas,
              Rect.fromLTWH(x, torsoTop + h * 0.005, w * 0.09, torsoH * 0.85), body, 6);
          final fx = x + w * 0.045;
          final fy = torsoTop + h * 0.005 + torsoH * 0.85;
          final path = Path()
            ..moveTo(fx - w * 0.03, fy)
            ..lineTo(fx, fy + h * 0.05)
            ..lineTo(fx + w * 0.03, fy)
            ..close();
          canvas.drawPath(path, flame);
        }
      case 'alas':
        final wing = Paint()..color = Colors.grey.shade100;
        final outline = Paint()
          ..color = Colors.grey.shade400
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        final leftWing = Path()
          ..moveTo(torsoX + torsoW * 0.2, torsoTop + torsoH * 0.15)
          ..quadraticBezierTo(torsoX - w * 0.30, torsoTop - h * 0.04,
              torsoX - w * 0.26, torsoTop + torsoH * 0.55)
          ..quadraticBezierTo(torsoX - w * 0.14, torsoTop + torsoH * 0.5,
              torsoX - w * 0.05, torsoTop + torsoH * 0.7)
          ..quadraticBezierTo(torsoX, torsoTop + torsoH * 0.4,
              torsoX + torsoW * 0.2, torsoTop + torsoH * 0.15)
          ..close();
        final rightWing = Path()
          ..moveTo(torsoX + torsoW * 0.8, torsoTop + torsoH * 0.15)
          ..quadraticBezierTo(torsoX + torsoW + w * 0.30, torsoTop - h * 0.04,
              torsoX + torsoW + w * 0.26, torsoTop + torsoH * 0.55)
          ..quadraticBezierTo(torsoX + torsoW + w * 0.14, torsoTop + torsoH * 0.5,
              torsoX + torsoW + w * 0.05, torsoTop + torsoH * 0.7)
          ..quadraticBezierTo(torsoX + torsoW, torsoTop + torsoH * 0.4,
              torsoX + torsoW * 0.8, torsoTop + torsoH * 0.15)
          ..close();
        canvas.drawPath(leftWing, wing);
        canvas.drawPath(leftWing, outline);
        canvas.drawPath(rightWing, wing);
        canvas.drawPath(rightWing, outline);
    }
  }

  void _drawShoulderAccessory(Canvas canvas) {
    final id = appearance.accessories.shoulders;
    if (id == null) return;
    switch (id) {
      case 'hombreras':
        final pad = Colors.grey.shade500;
        _drawRoundRect(
            canvas,
            Rect.fromLTWH(torsoX - armW * 1.1, armTop - h * 0.012,
                armW * 1.4, h * 0.045),
            pad,
            4);
        _drawRoundRect(
            canvas,
            Rect.fromLTWH(torsoX + torsoW - armW * 0.3, armTop - h * 0.012,
                armW * 1.4, h * 0.045),
            pad,
            4);
      case 'loro pirata':
        final shoulder = Offset(torsoX + torsoW + armW * 0.2, armTop - h * 0.015);
        final body = Paint()..color = Colors.green.shade600;
        canvas.drawOval(
            Rect.fromCenter(
                center: shoulder, width: w * 0.09, height: h * 0.075),
            body);
        canvas.drawCircle(
            Offset(shoulder.dx + w * 0.02, shoulder.dy - h * 0.045),
            w * 0.035, body);
        // Beak + eye
        final beak = Path()
          ..moveTo(shoulder.dx + w * 0.05, shoulder.dy - h * 0.05)
          ..lineTo(shoulder.dx + w * 0.085, shoulder.dy - h * 0.04)
          ..lineTo(shoulder.dx + w * 0.05, shoulder.dy - h * 0.032)
          ..close();
        canvas.drawPath(beak, Paint()..color = Colors.orange.shade700);
        canvas.drawCircle(
            Offset(shoulder.dx + w * 0.025, shoulder.dy - h * 0.05),
            1.5, Paint()..color = Colors.white);
      case 'insignia':
        drawStar4(
            canvas,
            Offset(torsoX + torsoW * 0.2, torsoTop + torsoH * 0.14),
            w * 0.05,
            Paint()..color = const Color(0xFFFFD700));
    }
  }

  void _drawNeckAccessory(Canvas canvas) {
    final id = appearance.accessories.neck;
    if (id == null) return;
    final cx = w / 2;
    switch (id) {
      case 'collar':
        final bead = Paint()..color = const Color(0xFFFFD700);
        for (var i = -2; i <= 2; i++) {
          canvas.drawCircle(
              Offset(cx + i * w * 0.05,
                  torsoTop + h * 0.015 + (i.abs() == 2 ? 0 : i.abs() == 1 ? h * 0.008 : h * 0.012)),
              2.2,
              bead);
        }
      case 'corbata':
        final tie = Paint()..color = Colors.red.shade800;
        final knot = Path()
          ..moveTo(cx - w * 0.03, torsoTop)
          ..lineTo(cx + w * 0.03, torsoTop)
          ..lineTo(cx + w * 0.02, torsoTop + h * 0.02)
          ..lineTo(cx - w * 0.02, torsoTop + h * 0.02)
          ..close();
        final blade = Path()
          ..moveTo(cx - w * 0.02, torsoTop + h * 0.02)
          ..lineTo(cx + w * 0.02, torsoTop + h * 0.02)
          ..lineTo(cx + w * 0.035, torsoTop + torsoH * 0.62)
          ..lineTo(cx, torsoTop + torsoH * 0.75)
          ..lineTo(cx - w * 0.035, torsoTop + torsoH * 0.62)
          ..close();
        canvas.drawPath(knot, tie);
        canvas.drawPath(blade, tie);
      case 'medallón':
        final chain = Paint()
          ..color = const Color(0xFFB8860B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawLine(Offset(cx - w * 0.09, torsoTop),
            Offset(cx, torsoTop + torsoH * 0.3), chain);
        canvas.drawLine(Offset(cx + w * 0.09, torsoTop),
            Offset(cx, torsoTop + torsoH * 0.3), chain);
        canvas.drawCircle(Offset(cx, torsoTop + torsoH * 0.36), w * 0.045,
            Paint()..color = const Color(0xFFFFD700));
      case 'bufanda':
        final scarf = Paint()..color = Colors.red.shade600;
        _drawRoundRect(
            canvas,
            Rect.fromLTWH(torsoX + torsoW * 0.08, torsoTop - h * 0.008,
                torsoW * 0.84, h * 0.035),
            scarf.color,
            4);
        _drawRoundRect(
            canvas,
            Rect.fromLTWH(cx - torsoW * 0.28, torsoTop + h * 0.02,
                torsoW * 0.16, torsoH * 0.55),
            scarf.color,
            4);
    }
  }

  void _drawWaistAccessory(Canvas canvas) {
    final id = appearance.accessories.waist;
    if (id == null) return;
    final beltRect = Rect.fromLTWH(
        (w - hipW) / 2, hipTop + hipH * 0.1, hipW, hipH * 0.55);
    switch (id) {
      case 'cinturón herramientas':
        _drawRoundRect(canvas, beltRect, Colors.brown.shade600, 3);
        final pouch = Paint()..color = Colors.brown.shade800;
        canvas.drawRect(
            Rect.fromLTWH(beltRect.left + hipW * 0.12, beltRect.bottom - 1,
                hipW * 0.14, hipH * 0.4),
            pouch);
        canvas.drawRect(
            Rect.fromLTWH(beltRect.right - hipW * 0.26, beltRect.bottom - 1,
                hipW * 0.14, hipH * 0.4),
            pouch);
      case 'faja ninja':
        _drawRoundRect(canvas, beltRect, Colors.grey.shade900, 3);
        // Knot tail
        _drawRoundRect(
            canvas,
            Rect.fromLTWH(beltRect.left + hipW * 0.06, beltRect.bottom,
                hipW * 0.09, hipH * 0.8),
            Colors.grey.shade900,
            2);
      case 'correa cowboy':
        _drawRoundRect(canvas, beltRect, Colors.brown.shade500, 3);
        canvas.drawRect(
            Rect.fromCenter(
                center: beltRect.center,
                width: hipW * 0.14,
                height: beltRect.height * 0.8),
            Paint()..color = const Color(0xFFFFD700));
    }
  }

  void _drawFaceAccessory(Canvas canvas) {
    final id = appearance.accessories.face;
    if (id == null) return;
    final hs = headSize;
    final eyeLX = hx + hs * 0.3;
    final eyeRX = hx + hs * 0.7;
    final eyeY = headTop + hs * 0.45;
    switch (id) {
      case 'gafas de sol':
        final lens = Paint()..color = Colors.black87;
        final frame = Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        for (final x in [eyeLX, eyeRX]) {
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromCenter(
                      center: Offset(x, eyeY), width: hs * 0.26, height: hs * 0.18),
                  const Radius.circular(3)),
              lens);
        }
        canvas.drawLine(Offset(eyeLX + hs * 0.13, eyeY),
            Offset(eyeRX - hs * 0.13, eyeY), frame);
        canvas.drawLine(Offset(hx, eyeY), Offset(eyeLX - hs * 0.13, eyeY), frame);
        canvas.drawLine(Offset(eyeRX + hs * 0.13, eyeY), Offset(hx + hs, eyeY), frame);
      case 'antifaz':
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(hx + hs * 0.1, eyeY - hs * 0.11, hs * 0.8, hs * 0.22),
                const Radius.circular(6)),
            Paint()..color = Colors.grey.shade900);
        final hole = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(eyeLX, eyeY), hs * 0.055, hole);
        canvas.drawCircle(Offset(eyeRX, eyeY), hs * 0.055, hole);
      case 'parche pirata':
        canvas.drawCircle(
            Offset(eyeRX, eyeY), hs * 0.13, Paint()..color = Colors.black);
        canvas.drawLine(
            Offset(hx, headTop + hs * 0.28),
            Offset(eyeRX + hs * 0.13, eyeY - hs * 0.10),
            Paint()
              ..color = Colors.black
              ..strokeWidth = 2.5);
      case 'máscara':
        _drawRoundRect(
            canvas,
            Rect.fromLTWH(hx + hs * 0.2, headTop + hs * 0.55, hs * 0.6, hs * 0.32),
            Colors.grey.shade600,
            6);
        final filter = Paint()..color = Colors.grey.shade800;
        canvas.drawCircle(
            Offset(hx + hs * 0.32, headTop + hs * 0.74), hs * 0.07, filter);
        canvas.drawCircle(
            Offset(hx + hs * 0.68, headTop + hs * 0.74), hs * 0.07, filter);
    }
  }

  void _drawFeetAccessory(Canvas canvas) {
    final id = appearance.accessories.feet;
    if (id == null) return;
    final leftShoe = Rect.fromLTWH(leftLegX - shoeOffset, shoeTop, shoeW, shoeH);
    final rightShoe = Rect.fromLTWH(rightLegX - shoeOffset, shoeTop, shoeW, shoeH);
    switch (id) {
      case 'espuelas':
        final spur = Paint()
          ..color = Colors.grey.shade600
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8;
        canvas.drawCircle(
            Offset(leftShoe.right, leftShoe.center.dy), shoeH * 0.28, spur);
        canvas.drawCircle(
            Offset(rightShoe.left, rightShoe.center.dy), shoeH * 0.28, spur);
      case 'tobilleras':
        final band = Paint()..color = const Color(0xFFFFD700);
        canvas.drawRect(
            Rect.fromLTWH(leftLegX, shoeTop - h * 0.022, legW, h * 0.018), band);
        canvas.drawRect(
            Rect.fromLTWH(rightLegX, shoeTop - h * 0.022, legW, h * 0.018), band);
      case 'botas propulsión':
        final flame = Paint()..color = Colors.orange.shade600;
        final inner = Paint()..color = Colors.yellow.shade600;
        for (final shoe in [leftShoe, rightShoe]) {
          final path = Path()
            ..moveTo(shoe.left + shoe.width * 0.2, shoe.bottom)
            ..lineTo(shoe.center.dx, shoe.bottom + h * 0.045)
            ..lineTo(shoe.right - shoe.width * 0.2, shoe.bottom)
            ..close();
          canvas.drawPath(path, flame);
          final small = Path()
            ..moveTo(shoe.left + shoe.width * 0.32, shoe.bottom)
            ..lineTo(shoe.center.dx, shoe.bottom + h * 0.025)
            ..lineTo(shoe.right - shoe.width * 0.32, shoe.bottom)
            ..close();
          canvas.drawPath(small, inner);
        }
    }
  }

  void _drawHandAccessory(Canvas canvas, String? id, Offset fist) {
    if (id == null) return;
    switch (id) {
      // Right hand
      case 'pistola':
        final metal = Paint()..color = Colors.grey.shade800;
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(fist.dx - w * 0.02, fist.dy - fistR * 2.0,
                    w * 0.13, fistR * 0.9),
                const Radius.circular(2)),
            metal);
        canvas.drawRect(
            Rect.fromLTWH(fist.dx - w * 0.02, fist.dy - fistR * 1.2,
                w * 0.035, fistR * 1.2),
            metal);
      case 'espada':
        final blade = Paint()..color = Colors.grey.shade400;
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(fist.dx - w * 0.014, fist.dy - h * 0.17,
                    w * 0.028, h * 0.15),
                const Radius.circular(2)),
            blade);
        canvas.drawRect(
            Rect.fromLTWH(fist.dx - w * 0.045, fist.dy - h * 0.03,
                w * 0.09, h * 0.012),
            Paint()..color = Colors.brown.shade700);
      case 'varita':
        canvas.drawRect(
            Rect.fromLTWH(fist.dx - w * 0.008, fist.dy - h * 0.13,
                w * 0.016, h * 0.13),
            Paint()..color = Colors.brown.shade600);
        drawStar4(canvas, Offset(fist.dx, fist.dy - h * 0.145), w * 0.035,
            Paint()..color = Colors.yellow.shade600);
      case 'antorcha':
        canvas.drawRect(
            Rect.fromLTWH(fist.dx - w * 0.012, fist.dy - h * 0.11,
                w * 0.024, h * 0.11),
            Paint()..color = Colors.brown.shade700);
        canvas.drawCircle(Offset(fist.dx, fist.dy - h * 0.125), w * 0.038,
            Paint()..color = Colors.orange.shade600);
        canvas.drawCircle(Offset(fist.dx, fist.dy - h * 0.13), w * 0.02,
            Paint()..color = Colors.yellow.shade600);
      case 'micrófono':
        canvas.drawRect(
            Rect.fromLTWH(fist.dx - w * 0.01, fist.dy - h * 0.10,
                w * 0.02, h * 0.10),
            Paint()..color = Colors.black87);
        canvas.drawCircle(Offset(fist.dx, fist.dy - h * 0.115), w * 0.032,
            Paint()..color = Colors.grey.shade700);
      case 'helado':
        final cone = Path()
          ..moveTo(fist.dx, fist.dy - fistR * 0.2)
          ..lineTo(fist.dx - w * 0.028, fist.dy - h * 0.075)
          ..lineTo(fist.dx + w * 0.028, fist.dy - h * 0.075)
          ..close();
        canvas.drawPath(cone, Paint()..color = const Color(0xFFD2B48C));
        canvas.drawCircle(Offset(fist.dx, fist.dy - h * 0.09), w * 0.032,
            Paint()..color = Colors.pink.shade300);

      // Left hand
      case 'bolso':
        _drawRoundRect(
            canvas,
            Rect.fromLTWH(fist.dx - w * 0.055, fist.dy + fistR * 0.6,
                w * 0.11, h * 0.06),
            Colors.brown.shade500,
            4);
        canvas.drawArc(
            Rect.fromLTWH(fist.dx - w * 0.03, fist.dy + fistR * 0.15,
                w * 0.06, h * 0.035),
            3.14159, 3.14159, false,
            Paint()
              ..color = Colors.brown.shade700
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      case 'linterna':
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(fist.dx - w * 0.018, fist.dy - h * 0.09,
                    w * 0.036, h * 0.075),
                const Radius.circular(2)),
            Paint()..color = Colors.amber.shade700);
        final beam = Path()
          ..moveTo(fist.dx - w * 0.018, fist.dy - h * 0.09)
          ..lineTo(fist.dx - w * 0.045, fist.dy - h * 0.14)
          ..lineTo(fist.dx + w * 0.045, fist.dy - h * 0.14)
          ..lineTo(fist.dx + w * 0.018, fist.dy - h * 0.09)
          ..close();
        canvas.drawPath(
            beam, Paint()..color = Colors.yellow.withValues(alpha: 0.55));
      case 'escudo':
        final shield = Path()
          ..moveTo(fist.dx - w * 0.07, fist.dy - h * 0.06)
          ..lineTo(fist.dx + w * 0.07, fist.dy - h * 0.06)
          ..lineTo(fist.dx + w * 0.06, fist.dy + h * 0.02)
          ..lineTo(fist.dx, fist.dy + h * 0.055)
          ..lineTo(fist.dx - w * 0.06, fist.dy + h * 0.02)
          ..close();
        canvas.drawPath(shield, Paint()..color = Colors.grey.shade500);
        canvas.drawPath(
            shield,
            Paint()
              ..color = Colors.grey.shade800
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      case 'libro':
        _drawRoundRect(
            canvas,
            Rect.fromLTWH(fist.dx - w * 0.05, fist.dy - h * 0.075,
                w * 0.10, h * 0.065),
            Colors.blue.shade800,
            2);
        canvas.drawLine(
            Offset(fist.dx, fist.dy - h * 0.072),
            Offset(fist.dx, fist.dy - h * 0.013),
            Paint()
              ..color = Colors.white
              ..strokeWidth = 1.5);
      case 'bomba':
        canvas.drawCircle(Offset(fist.dx, fist.dy + fistR * 1.6), w * 0.05,
            Paint()..color = Colors.black87);
        canvas.drawLine(
            Offset(fist.dx + w * 0.02, fist.dy + fistR * 1.0),
            Offset(fist.dx + w * 0.04, fist.dy + fistR * 0.4),
            Paint()
              ..color = Colors.brown.shade600
              ..strokeWidth = 2);
        canvas.drawCircle(Offset(fist.dx + w * 0.045, fist.dy + fistR * 0.3),
            w * 0.014, Paint()..color = Colors.orange);
      case 'escoba':
        canvas.drawRect(
            Rect.fromLTWH(fist.dx - w * 0.01, fist.dy - h * 0.12,
                w * 0.02, h * 0.20),
            Paint()..color = Colors.brown.shade600);
        final bristles = Path()
          ..moveTo(fist.dx - w * 0.04, fist.dy + h * 0.08)
          ..lineTo(fist.dx + w * 0.04, fist.dy + h * 0.08)
          ..lineTo(fist.dx + w * 0.055, fist.dy + h * 0.14)
          ..lineTo(fist.dx - w * 0.055, fist.dy + h * 0.14)
          ..close();
        canvas.drawPath(bristles, Paint()..color = const Color(0xFFD2B48C));
    }
  }

  // ── Headwear ────────────────────────────────────────────────────────────────

  void _drawHeadwear(Canvas canvas) {
    switch (appearance.headwearType) {
      case HeadwearType.none:
        break;
      case HeadwearType.hair:
        _drawHair(canvas, hx, headTop, headSize);
      case HeadwearType.helmet:
        _drawHelmet(canvas, hx, headTop, headSize);
      case HeadwearType.hat:
        _drawHat(canvas, hx, headTop, headSize);
    }
  }

  void _drawHair(Canvas canvas, double hx, double hy, double hs) {
    final style = appearance.hairStyle ?? HairStyle.straight;
    if (style == HairStyle.bald) return;
    final color = hairColorFor(style);

    switch (style) {
      case HairStyle.straight:
        _drawRoundRect(canvas, Rect.fromLTWH(hx - 2, hy - hs * 0.12, hs + 4, hs * 0.35), color, 6);
      case HairStyle.curly:
        final paint = Paint()..color = color;
        final r = hs * 0.14;
        for (var i = 0; i < 5; i++) {
          canvas.drawCircle(
              Offset(hx + hs * (0.1 + i * 0.2), hy - hs * 0.02), r, paint);
        }
        canvas.drawCircle(Offset(hx, hy + hs * 0.14), r * 0.9, paint);
        canvas.drawCircle(Offset(hx + hs, hy + hs * 0.14), r * 0.9, paint);
      case HairStyle.afro:
        canvas.drawCircle(
            Offset(hx + hs / 2, hy - hs * 0.02), hs * 0.42, Paint()..color = color);
      case HairStyle.mohawk:
        _drawRoundRect(canvas, Rect.fromLTWH(hx - 1, hy - hs * 0.04, hs + 2, hs * 0.16),
            Colors.grey.shade800, 4);
        _drawRoundRect(
            canvas,
            Rect.fromLTWH(hx + hs * 0.41, hy - hs * 0.32, hs * 0.18, hs * 0.40),
            color,
            3);
      case HairStyle.ponytail:
        _drawRoundRect(canvas, Rect.fromLTWH(hx - 2, hy - hs * 0.12, hs + 4, hs * 0.35), color, 6);
        _drawRoundRect(
            canvas,
            Rect.fromLTWH(hx + hs * 0.92, hy + hs * 0.10, hs * 0.15, hs * 0.58),
            color,
            5);
      case HairStyle.braids:
        _drawRoundRect(canvas, Rect.fromLTWH(hx - 2, hy - hs * 0.12, hs + 4, hs * 0.35), color, 6);
        _drawRoundRect(canvas,
            Rect.fromLTWH(hx - hs * 0.10, hy + hs * 0.10, hs * 0.13, hs * 0.62), color, 5);
        _drawRoundRect(canvas,
            Rect.fromLTWH(hx + hs * 0.97, hy + hs * 0.10, hs * 0.13, hs * 0.62), color, 5);
        final tie = Paint()..color = Colors.red.shade400;
        canvas.drawRect(
            Rect.fromLTWH(hx - hs * 0.10, hy + hs * 0.60, hs * 0.13, hs * 0.06), tie);
        canvas.drawRect(
            Rect.fromLTWH(hx + hs * 0.97, hy + hs * 0.60, hs * 0.13, hs * 0.06), tie);
      case HairStyle.shaved:
        _drawRoundRect(canvas,
            Rect.fromLTWH(hx - 1, hy - hs * 0.05, hs + 2, hs * 0.16), color, 4);
      case HairStyle.bald:
        break;
    }
  }

  void _drawHelmet(Canvas canvas, double hx, double hy, double hs) {
    final style = appearance.helmetStyle ?? HelmetStyle.medieval;
    final color = helmetColorFor(style);

    // Dome — bikers get a lower-profile shell
    final domeH = style == HelmetStyle.biker ? hs * 0.38 : hs * 0.5;
    _drawRoundRect(canvas, Rect.fromLTWH(hx - 3, hy - hs * 0.15, hs + 6, domeH), color, 10);

    switch (style) {
      case HelmetStyle.medieval:
        // Cross-slit visor
        final slit = Paint()..color = Colors.grey.shade900;
        canvas.drawRect(
            Rect.fromLTWH(hx + hs * 0.15, hy + hs * 0.22, hs * 0.7, hs * 0.06), slit);
        canvas.drawRect(
            Rect.fromLTWH(hx + hs * 0.46, hy + hs * 0.10, hs * 0.08, hs * 0.24), slit);
      case HelmetStyle.space:
        canvas.drawRect(
            Rect.fromLTWH(hx + hs * 0.15, hy + hs * 0.2, hs * 0.7, hs * 0.12),
            Paint()..color = Colors.lightBlue.withValues(alpha: 0.6));
      case HelmetStyle.roman:
        // Crest on top
        _drawRoundRect(canvas,
            Rect.fromLTWH(hx + hs * 0.38, hy - hs * 0.40, hs * 0.24, hs * 0.30),
            Colors.red.shade900, 4);
        canvas.drawRect(
            Rect.fromLTWH(hx + hs * 0.15, hy + hs * 0.22, hs * 0.7, hs * 0.07),
            Paint()..color = Colors.grey.shade800);
      case HelmetStyle.viking:
        // Horns
        final horn = Paint()..color = const Color(0xFFF5F0E0);
        final leftHorn = Path()
          ..moveTo(hx - 2, hy + hs * 0.05)
          ..lineTo(hx - hs * 0.20, hy - hs * 0.28)
          ..lineTo(hx + hs * 0.06, hy - hs * 0.06)
          ..close();
        final rightHorn = Path()
          ..moveTo(hx + hs + 2, hy + hs * 0.05)
          ..lineTo(hx + hs + hs * 0.20, hy - hs * 0.28)
          ..lineTo(hx + hs - hs * 0.06, hy - hs * 0.06)
          ..close();
        canvas.drawPath(leftHorn, horn);
        canvas.drawPath(rightHorn, horn);
      case HelmetStyle.firefighter:
        // Wide protective brim
        _drawRoundRect(canvas,
            Rect.fromLTWH(hx - hs * 0.12, hy + hs * 0.26, hs * 1.24, hs * 0.10),
            Colors.yellow.shade800, 3);
      case HelmetStyle.biker:
        canvas.drawRect(
            Rect.fromLTWH(hx + hs * 0.1, hy + hs * 0.12, hs * 0.8, hs * 0.05),
            Paint()..color = Colors.grey.shade700);
      case HelmetStyle.astronaut:
        // Big golden visor
        _drawRoundRect(canvas,
            Rect.fromLTWH(hx + hs * 0.12, hy + hs * 0.12, hs * 0.76, hs * 0.26),
            Colors.amber.withValues(alpha: 0.75), 8);
    }
  }

  void _drawHat(Canvas canvas, double hx, double hy, double hs) {
    final style = appearance.hatStyle ?? HatStyle.cap;
    final color = hatColorFor(style);

    switch (style) {
      case HatStyle.wizard:
        _drawRoundRect(canvas,
            Rect.fromLTWH(hx - hs * 0.1, hy + hs * 0.02, hs * 1.2, hs * 0.12),
            Colors.indigo.shade800, 3);
        final cone = Path()
          ..moveTo(hx + hs * 0.1, hy + hs * 0.04)
          ..lineTo(hx + hs * 0.5, hy - hs * 0.45)
          ..lineTo(hx + hs * 0.9, hy + hs * 0.04)
          ..close();
        canvas.drawPath(cone, Paint()..color = color);
        drawStar4(canvas, Offset(hx + hs * 0.5, hy - hs * 0.16), hs * 0.08,
            Paint()..color = Colors.yellow.shade600);
      case HatStyle.cowboy:
        // Extra-wide brim with upturned edges
        _drawRoundRect(canvas,
            Rect.fromLTWH(hx - hs * 0.22, hy + hs * 0.02, hs * 1.44, hs * 0.12),
            Colors.brown.shade600, 6);
        _drawRoundRect(canvas,
            Rect.fromLTWH(hx + hs * 0.12, hy - hs * 0.22, hs * 0.76, hs * 0.27), color, 5);
        canvas.drawRect(
            Rect.fromLTWH(hx + hs * 0.12, hy - hs * 0.04, hs * 0.76, hs * 0.06),
            Paint()..color = Colors.brown.shade800);
      case HatStyle.cap:
        _drawRoundRect(canvas,
            Rect.fromLTWH(hx + hs * 0.3, hy + hs * 0.02, hs * 0.85, hs * 0.10),
            color, 3);
        _drawRoundRect(canvas,
            Rect.fromLTWH(hx + hs * 0.02, hy - hs * 0.20, hs * 0.96, hs * 0.26), color, 8);
        canvas.drawCircle(Offset(hx + hs * 0.5, hy - hs * 0.18), hs * 0.04,
            Paint()..color = Colors.red.shade800);
      case HatStyle.crown:
        final path = Path()
          ..moveTo(hx + hs * 0.15, hy + hs * 0.02)
          ..lineTo(hx + hs * 0.15, hy - hs * 0.22)
          ..lineTo(hx + hs * 0.3, hy - hs * 0.1)
          ..lineTo(hx + hs * 0.5, hy - hs * 0.28)
          ..lineTo(hx + hs * 0.7, hy - hs * 0.1)
          ..lineTo(hx + hs * 0.85, hy - hs * 0.22)
          ..lineTo(hx + hs * 0.85, hy + hs * 0.02)
          ..close();
        canvas.drawPath(path, Paint()..color = color);
        canvas.drawCircle(Offset(hx + hs * 0.5, hy - hs * 0.06), hs * 0.05,
            Paint()..color = Colors.red.shade600);
      case HatStyle.tiara:
        // Thinner silver band with a pink gem
        final path = Path()
          ..moveTo(hx + hs * 0.25, hy + hs * 0.02)
          ..lineTo(hx + hs * 0.25, hy - hs * 0.08)
          ..lineTo(hx + hs * 0.38, hy - hs * 0.02)
          ..lineTo(hx + hs * 0.5, hy - hs * 0.18)
          ..lineTo(hx + hs * 0.62, hy - hs * 0.02)
          ..lineTo(hx + hs * 0.75, hy - hs * 0.08)
          ..lineTo(hx + hs * 0.75, hy + hs * 0.02)
          ..close();
        canvas.drawPath(path, Paint()..color = color);
        canvas.drawCircle(Offset(hx + hs * 0.5, hy - hs * 0.08), hs * 0.045,
            Paint()..color = Colors.pink.shade300);
      case HatStyle.topHat:
        _drawRoundRect(canvas,
            Rect.fromLTWH(hx - hs * 0.1, hy + hs * 0.02, hs * 1.2, hs * 0.10), color, 3);
        _drawRoundRect(canvas,
            Rect.fromLTWH(hx + hs * 0.12, hy - hs * 0.48, hs * 0.76, hs * 0.52), color, 4);
        canvas.drawRect(
            Rect.fromLTWH(hx + hs * 0.12, hy - hs * 0.08, hs * 0.76, hs * 0.08),
            Paint()..color = Colors.grey.shade700);
      case HatStyle.pirate:
        // Tricorn: wide brim with upturned sides
        final tricorn = Path()
          ..moveTo(hx - hs * 0.18, hy + hs * 0.10)
          ..lineTo(hx - hs * 0.10, hy - hs * 0.22)
          ..quadraticBezierTo(hx + hs * 0.5, hy - hs * 0.38,
              hx + hs + hs * 0.10, hy - hs * 0.22)
          ..lineTo(hx + hs + hs * 0.18, hy + hs * 0.10)
          ..close();
        canvas.drawPath(tricorn, Paint()..color = color);
        // Skull mark
        canvas.drawCircle(Offset(hx + hs * 0.5, hy - hs * 0.12), hs * 0.06,
            Paint()..color = Colors.white);
    }
  }

  // ── Face (eyes / mouth) ─────────────────────────────────────────────────────

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

  // ── Helpers ─────────────────────────────────────────────────────────────────

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

  @override
  bool shouldRepaint(_CharacterPainter oldDelegate) =>
      oldDelegate.appearance != appearance;
}
