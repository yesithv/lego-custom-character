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
    // Long hair falls over the shoulders, in front of the torso
    _drawLongHairOverlay(canvas);
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
    drawPlasticSphere(canvas, Offset(w / 2, headTop - studR * 0.35), studR, skin);
    _drawRoundRect(canvas, Rect.fromLTWH(hx, headTop, headSize, headSize), skin, 8);
    // Extra glossy highlight on the cheek — LEGO heads are the shiniest piece
    canvas.drawOval(
      Rect.fromLTWH(hx + headSize * 0.08, headTop + headSize * 0.10,
          headSize * 0.22, headSize * 0.34),
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );
  }

  void _drawNeckAndTorso(Canvas canvas) {
    final neckW = headSize * 0.30;
    _drawRoundRect(canvas, Rect.fromLTWH((w - neckW) / 2, neckTop, neckW, neckH), skin, 3);
    _drawRoundRect(canvas, Rect.fromLTWH(torsoX, torsoTop, torsoW, torsoH), torsoColor, 6);
    // Contact shadow cast by the head onto the shoulders
    drawContactShadow(
        canvas,
        Rect.fromCenter(
            center: Offset(w / 2, torsoTop + torsoH * 0.05),
            width: headSize * 0.85,
            height: torsoH * 0.10));
    _drawTorsoDetail(canvas);
  }

  void _drawArmsAndHands(Canvas canvas) {
    _drawRoundRect(canvas, Rect.fromLTWH(torsoX - armW, armTop, armW, armH), skin, 4);
    _drawRoundRect(canvas, Rect.fromLTWH(torsoX + torsoW, armTop, armW, armH), skin, 4);

    // Shoulder knobs (torso color, at arm-torso junction)
    final knobR = armW * 0.55;
    drawPlasticSphere(canvas, Offset(torsoX, armTop + knobR), knobR, torsoColor);
    drawPlasticSphere(
        canvas, Offset(torsoX + torsoW, armTop + knobR), knobR, torsoColor);

    // Fists — colored by glove type
    final gloveColor = gloveColorFor(appearance.gloves, skin);
    final r = appearance.gloves == GloveType.boxing ? fistR * 1.35 : fistR;
    drawPlasticSphere(canvas, leftFist, r, gloveColor);
    drawPlasticSphere(canvas, rightFist, r, gloveColor);
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
    // Contact shadow cast by the torso onto the hip piece
    drawContactShadow(
        canvas,
        Rect.fromCenter(
            center: Offset(w / 2, hipTop + hipH * 0.18),
            width: torsoW * 0.90,
            height: hipH * 0.30));

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
        final skirtL = (w - hipW) / 2 - w * 0.05;
        final skirtR = (w + hipW) / 2 + w * 0.05;
        final skirtHem = legTop + legH * 0.40;
        final skirt = Path()
          ..moveTo((w - hipW) / 2, hipTop)
          ..lineTo((w + hipW) / 2, hipTop)
          ..lineTo(skirtR, skirtHem)
          ..quadraticBezierTo(w * 0.62, skirtHem + w * 0.03, w / 2, skirtHem)
          ..quadraticBezierTo(w * 0.38, skirtHem + w * 0.03, skirtL, skirtHem)
          ..close();
        drawShadedPath(canvas, skirt, legColor);
        // Fold lines
        final fold = Paint()
          ..color = darkenColor(legColor, 0.16).withValues(alpha: 0.55)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
        for (final fx in [0.38, 0.5, 0.62]) {
          canvas.drawLine(Offset(w * fx, hipTop + hipH * 0.8),
              Offset(w * fx, skirtHem - 2), fold);
        }

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
      case TorsoDesign.tactical:
        // Chaleco táctico: correas verticales y bolsillos con solapa
        final strapP = Paint()..color = const Color(0xFF3A4148);
        canvas.drawRect(
            Rect.fromLTWH(torsoX + torsoW * 0.22, torsoTop, torsoW * 0.09, torsoH),
            strapP);
        canvas.drawRect(
            Rect.fromLTWH(torsoX + torsoW * 0.69, torsoTop, torsoW * 0.09, torsoH),
            strapP);
        final pouch = const Color(0xFF4A545C);
        for (final px in [0.28, 0.54]) {
          for (final py in [0.30, 0.62]) {
            drawPlasticRect(
                canvas,
                Rect.fromLTWH(torsoX + torsoW * px, torsoTop + torsoH * py,
                    torsoW * 0.18, torsoH * 0.22),
                pouch,
                2,
                sheen: false);
          }
        }
        // Cierre frontal
        canvas.drawRect(
            Rect.fromLTWH(cx - 1, torsoTop, 2, torsoH),
            Paint()..color = Colors.black.withValues(alpha: 0.45));
      case TorsoDesign.tanktop:
        // Camiseta sin mangas: hombros de piel visibles y cinturón rojo
        final skinP = Paint()..color = skin;
        canvas.drawRect(
            Rect.fromLTWH(torsoX, torsoTop, torsoW * 0.14, torsoH * 0.30), skinP);
        canvas.drawRect(
            Rect.fromLTWH(torsoX + torsoW * 0.86, torsoTop, torsoW * 0.14,
                torsoH * 0.30),
            skinP);
        // Tirantes
        final strap = Paint()..color = darkenColor(torsoColor, 0.15);
        canvas.drawRect(
            Rect.fromLTWH(torsoX + torsoW * 0.14, torsoTop, torsoW * 0.10,
                torsoH * 0.30),
            strap);
        canvas.drawRect(
            Rect.fromLTWH(torsoX + torsoW * 0.76, torsoTop, torsoW * 0.10,
                torsoH * 0.30),
            strap);
        // Cinturón rojo con hebilla
        canvas.drawRect(
            Rect.fromLTWH(torsoX, torsoTop + torsoH * 0.82, torsoW, torsoH * 0.16),
            Paint()..color = const Color(0xFFC62828));
        drawPlasticRect(
            canvas,
            Rect.fromCenter(
                center: Offset(cx, torsoTop + torsoH * 0.90),
                width: torsoW * 0.14,
                height: torsoH * 0.12),
            const Color(0xFFB0BEC5),
            2,
            sheen: false);
      case TorsoDesign.commando:
        // Chaleco comando: manchas de camuflaje y bandolera con bolsillos
        final blotch = Paint()..color = const Color(0xFF37432B);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(torsoX + torsoW * 0.30, torsoTop + torsoH * 0.28),
                width: torsoW * 0.32,
                height: torsoH * 0.18),
            blotch);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(torsoX + torsoW * 0.68, torsoTop + torsoH * 0.60),
                width: torsoW * 0.30,
                height: torsoH * 0.16),
            blotch);
        // Bandolera diagonal
        canvas.drawPath(
          Path()
            ..moveTo(torsoX + torsoW * 0.10, torsoTop)
            ..lineTo(torsoX + torsoW * 0.24, torsoTop)
            ..lineTo(torsoX + torsoW * 0.96, torsoTop + torsoH)
            ..lineTo(torsoX + torsoW * 0.82, torsoTop + torsoH)
            ..close(),
          Paint()..color = const Color(0xFF2E2A20),
        );
        // Bolsillos amarillos del cinturón
        final ammo = const Color(0xFFC9B037);
        for (final px in [0.16, 0.42]) {
          drawPlasticRect(
              canvas,
              Rect.fromLTWH(torsoX + torsoW * px, torsoTop + torsoH * 0.74,
                  torsoW * 0.16, torsoH * 0.20),
              ammo,
              2,
              sheen: false);
        }
    }
  }

  // ── Cape ────────────────────────────────────────────────────────────────────

  void _drawLongCape(Canvas canvas) {
    final capeColor = Colors.red.shade700;
    final hemY = legTop + legH * 0.55;
    final capeL = torsoX - armW * 1.1;
    final capeR = torsoX + torsoW + armW * 1.1;
    // Wavy hem so the fabric reads as cloth, not a flat block
    final path = Path()
      ..moveTo(torsoX - armW * 0.4, torsoTop)
      ..lineTo(torsoX + torsoW + armW * 0.4, torsoTop)
      ..lineTo(capeR, hemY)
      ..quadraticBezierTo(
          capeR - (capeR - capeL) * 0.17, hemY + h * 0.020, w * 0.62, hemY)
      ..quadraticBezierTo(w / 2, hemY + h * 0.024, w * 0.38, hemY)
      ..quadraticBezierTo(
          capeL + (capeR - capeL) * 0.17, hemY + h * 0.020, capeL, hemY)
      ..close();
    drawShadedPath(canvas, path, capeColor);
    // Inner fold shading
    final fold = Paint()
      ..color = darkenColor(capeColor, 0.18).withValues(alpha: 0.50)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(torsoX + torsoW * 0.16, torsoTop + torsoH * 0.3),
        Offset(capeL + armW * 0.7, hemY - 3), fold);
    canvas.drawLine(Offset(torsoX + torsoW * 0.84, torsoTop + torsoH * 0.3),
        Offset(capeR - armW * 0.7, hemY - 3), fold);
  }

  // ── Accessories ─────────────────────────────────────────────────────────────

  void _drawBackAccessory(Canvas canvas) {
    final id = appearance.accessories.back;
    if (id == null) return;
    switch (id) {
      case 'capa corta':
        final hemY = hipTop + hipH;
        final path = Path()
          ..moveTo(torsoX - armW * 0.3, torsoTop)
          ..lineTo(torsoX + torsoW + armW * 0.3, torsoTop)
          ..lineTo(torsoX + torsoW + armW * 0.7, hemY)
          ..quadraticBezierTo(w * 0.5, hemY + h * 0.018, torsoX - armW * 0.7, hemY)
          ..close();
        drawShadedPath(canvas, path, Colors.blue.shade800);
      case 'capa vampiro':
        final vHemY = legTop + legH * 0.5;
        final vL = torsoX - armW * 1.3;
        final vR = torsoX + torsoW + armW * 1.3;
        // Jagged bat-wing hem
        final path = Path()
          ..moveTo(torsoX - armW * 0.5, torsoTop)
          ..lineTo(torsoX + torsoW + armW * 0.5, torsoTop)
          ..lineTo(vR, vHemY);
        const points = 4;
        for (var i = 1; i <= points; i++) {
          final x = vR - (vR - vL) * i / points;
          path
            ..lineTo(x + (vR - vL) / points / 2, vHemY - h * 0.022)
            ..lineTo(x, vHemY);
        }
        path.close();
        drawShadedPath(canvas, path, Colors.grey.shade900);
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
        // Feather separation strokes
        final feather = Paint()
          ..color = Colors.grey.shade400.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        for (final t in [0.35, 0.55]) {
          canvas.drawLine(
              Offset(torsoX - w * 0.22 + w * 0.05, torsoTop + torsoH * t),
              Offset(torsoX - w * 0.02, torsoTop + torsoH * (t + 0.12)),
              feather);
          canvas.drawLine(
              Offset(torsoX + torsoW + w * 0.22 - w * 0.05, torsoTop + torsoH * t),
              Offset(torsoX + torsoW + w * 0.02, torsoTop + torsoH * (t + 0.12)),
              feather);
        }
      case 'alas mariposa':
        // Dos pares de alas rosadas con motas, como de hada
        final upper = Colors.pink.shade300;
        final lower = Colors.purple.shade200;
        final spot = Paint()..color = Colors.white.withValues(alpha: 0.75);
        for (final side in [-1, 1]) {
          final anchorX = side < 0 ? torsoX : torsoX + torsoW;
          canvas.save();
          canvas.translate(anchorX, torsoTop + torsoH * 0.15);
          canvas.rotate(side * 0.45);
          // Ala superior grande — asoma por encima del hombro
          final upperR = Rect.fromCenter(
              center: Offset(side * w * 0.17, -torsoH * 0.30),
              width: w * 0.30,
              height: torsoH * 0.85);
          drawShadedPath(canvas, Path()..addOval(upperR), upper);
          // Ala inferior pequeña
          final lowerR = Rect.fromCenter(
              center: Offset(side * w * 0.13, torsoH * 0.42),
              width: w * 0.22,
              height: torsoH * 0.55);
          drawShadedPath(canvas, Path()..addOval(lowerR), lower);
          // Motas
          canvas.drawCircle(upperR.center, w * 0.040, spot);
          canvas.drawCircle(
              Offset(lowerR.center.dx, lowerR.center.dy + torsoH * 0.04),
              w * 0.026, spot);
          canvas.restore();
        }
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
      case 'gatito':
        // Gatito naranja sentado en el hombro izquierdo
        final catX = torsoX + torsoW * 0.14;
        final catY = armTop - h * 0.012;
        final orange = Colors.orange.shade400;
        // Cola curvada
        canvas.drawPath(
          Path()
            ..moveTo(catX + w * 0.045, catY + h * 0.012)
            ..quadraticBezierTo(catX + w * 0.10, catY + h * 0.008,
                catX + w * 0.085, catY - h * 0.030),
          Paint()
            ..color = orange
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0
            ..strokeCap = StrokeCap.round,
        );
        // Cuerpo
        drawShadedPath(
            canvas,
            Path()
              ..addOval(Rect.fromCenter(
                  center: Offset(catX, catY + h * 0.005),
                  width: w * 0.095,
                  height: h * 0.055)),
            orange);
        // Cabeza con orejas
        final headC = Offset(catX - w * 0.015, catY - h * 0.042);
        for (final ear in [-1, 1]) {
          final earPath = Path()
            ..moveTo(headC.dx + ear * w * 0.008, headC.dy - w * 0.028)
            ..lineTo(headC.dx + ear * w * 0.036, headC.dy - w * 0.052)
            ..lineTo(headC.dx + ear * w * 0.038, headC.dy - w * 0.016)
            ..close();
          canvas.drawPath(earPath, Paint()..color = orange);
        }
        drawPlasticSphere(canvas, headC, w * 0.037, orange);
        // Carita
        final dot = Paint()..color = Colors.black87;
        canvas.drawCircle(Offset(headC.dx - w * 0.013, headC.dy - w * 0.006), 1.1, dot);
        canvas.drawCircle(Offset(headC.dx + w * 0.013, headC.dy - w * 0.006), 1.1, dot);
        canvas.drawCircle(Offset(headC.dx, headC.dy + w * 0.008), 1.0,
            Paint()..color = Colors.pink.shade300);
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
        drawPlasticSphere(canvas, Offset(cx, torsoTop + torsoH * 0.36),
            w * 0.045, const Color(0xFFFFD700));
      case 'perlas':
        // Collar de perlas: arco de esferas blancas con caída central
        for (var i = -3; i <= 3; i++) {
          final t = i / 3.0;
          final px = cx + t * torsoW * 0.30;
          final py = torsoTop + h * 0.006 + (1 - t * t) * h * 0.020;
          drawPlasticSphere(canvas, Offset(px, py),
              w * (i == 0 ? 0.024 : 0.019), const Color(0xFFF7F3EE));
        }
      case 'bandana':
        // Pañuelo amarillo anudado al cuello, con pico triangular
        final yellow = const Color(0xFFE8D44D);
        final kerchief = Path()
          ..moveTo(cx - torsoW * 0.30, torsoTop - h * 0.004)
          ..lineTo(cx + torsoW * 0.30, torsoTop - h * 0.004)
          ..lineTo(cx, torsoTop + torsoH * 0.42)
          ..close();
        drawShadedPath(canvas, kerchief, yellow);
        // Pliegues del nudo
        final foldLine = Paint()
          ..color = darkenColor(yellow, 0.18).withValues(alpha: 0.6)
          ..strokeWidth = 1.2;
        canvas.drawLine(Offset(cx - torsoW * 0.12, torsoTop + h * 0.008),
            Offset(cx - torsoW * 0.02, torsoTop + torsoH * 0.28), foldLine);
        canvas.drawLine(Offset(cx + torsoW * 0.12, torsoTop + h * 0.008),
            Offset(cx + torsoW * 0.02, torsoTop + torsoH * 0.28), foldLine);
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
      case 'tutú':
        // Tutú de bailarina: falda de tul rosa con volantes
        final pink = Colors.pink.shade300;
        final tutuL = (w - hipW) / 2 - w * 0.07;
        final tutuR = (w + hipW) / 2 + w * 0.07;
        final hem = legTop + legH * 0.22;
        final path = Path()
          ..moveTo((w - hipW) / 2, hipTop)
          ..lineTo((w + hipW) / 2, hipTop)
          ..lineTo(tutuR, hem);
        const ruffles = 5;
        for (var i = 1; i <= ruffles; i++) {
          final x = tutuR - (tutuR - tutuL) * i / ruffles;
          path.quadraticBezierTo(
              x + (tutuR - tutuL) / ruffles / 2, hem + w * 0.05, x, hem);
        }
        path.close();
        drawShadedPath(canvas, path, pink);
        // Capa interior de tul más clara
        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.22)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0,
        );
        // Cinturilla
        _drawRoundRect(
            canvas,
            Rect.fromLTWH((w - hipW) / 2, hipTop, hipW, hipH * 0.35),
            Colors.pink.shade400,
            3);
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
      case 'moño rosa':
        // Lazo en lo alto de la cabeza, ladeado
        final bowC = Offset(hx + hs * 0.80, headTop - hs * 0.02);
        _drawBow(canvas, bowC, hs * 0.22, Colors.pink.shade400);
      case 'ojo biónico':
        // Implante biónico sobre el ojo derecho, con cicatriz
        canvas.drawCircle(Offset(eyeRX, eyeY), hs * 0.15,
            Paint()..color = const Color(0xFF37474F));
        canvas.drawCircle(Offset(eyeRX, eyeY), hs * 0.085,
            Paint()..color = const Color(0xFFFF1744));
        canvas.drawCircle(Offset(eyeRX, eyeY), hs * 0.15,
            Paint()
              ..color = const Color(0xFFFF1744).withValues(alpha: 0.25)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.0);
        // Cicatriz que cruza la ceja y la mejilla
        final scar = Paint()
          ..color = const Color(0xFF8D5524).withValues(alpha: 0.85)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(eyeRX - hs * 0.05, eyeY - hs * 0.24),
            Offset(eyeRX + hs * 0.02, eyeY - hs * 0.17), scar);
        canvas.drawLine(Offset(eyeRX + hs * 0.06, eyeY + hs * 0.17),
            Offset(eyeRX + hs * 0.13, eyeY + hs * 0.26), scar);
      case 'gafas tácticas':
        // Visor envolvente oscuro de una pieza
        final visor = Path()
          ..moveTo(hx + hs * 0.06, eyeY - hs * 0.09)
          ..lineTo(hx + hs * 0.94, eyeY - hs * 0.09)
          ..lineTo(hx + hs * 0.88, eyeY + hs * 0.11)
          ..quadraticBezierTo(hx + hs * 0.5, eyeY + hs * 0.17,
              hx + hs * 0.12, eyeY + hs * 0.11)
          ..close();
        drawShadedPath(canvas, visor, const Color(0xFF1C1C1C));
        // Reflejo diagonal en el visor
        canvas.drawLine(
            Offset(hx + hs * 0.24, eyeY + hs * 0.07),
            Offset(hx + hs * 0.40, eyeY - hs * 0.06),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.45)
              ..strokeWidth = 2.2);
      case 'pendientes':
        final gold = const Color(0xFFFFD700);
        final earY = headTop + hs * 0.55;
        for (final ex in [hx - 1.5, hx + hs + 1.5]) {
          drawPlasticSphere(canvas, Offset(ex, earY), hs * 0.055, gold);
          // Gotita rosa colgante
          canvas.drawOval(
              Rect.fromCenter(
                  center: Offset(ex, earY + hs * 0.13),
                  width: hs * 0.07,
                  height: hs * 0.11),
              Paint()..color = Colors.pink.shade300);
        }
    }
  }

  /// Lazo de dos bucles con nudo central.
  void _drawBow(Canvas canvas, Offset c, double size, Color color) {
    final loopL = Path()
      ..moveTo(c.dx, c.dy)
      ..quadraticBezierTo(
          c.dx - size, c.dy - size * 0.75, c.dx - size * 0.9, c.dy + size * 0.25)
      ..close();
    final loopR = Path()
      ..moveTo(c.dx, c.dy)
      ..quadraticBezierTo(
          c.dx + size, c.dy - size * 0.75, c.dx + size * 0.9, c.dy + size * 0.25)
      ..close();
    drawShadedPath(canvas, loopL, color);
    drawShadedPath(canvas, loopR, color);
    drawPlasticSphere(canvas, c, size * 0.28, darkenColor(color, 0.10));
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
      case 'moños zapatos':
        // Lazo rosa sobre el empeine de cada zapato
        for (final shoe in [leftShoe, rightShoe]) {
          _drawBow(canvas, Offset(shoe.center.dx, shoe.top + shoe.height * 0.15),
              shoe.width * 0.28, Colors.pink.shade400);
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
        // Polished blade with a pointed tip and center ridge
        final bladeRect = Rect.fromLTWH(
            fist.dx - w * 0.014, fist.dy - h * 0.165, w * 0.028, h * 0.145);
        final bladePath = Path()
          ..moveTo(fist.dx, bladeRect.top - h * 0.014)
          ..lineTo(bladeRect.right, bladeRect.top)
          ..lineTo(bladeRect.right, bladeRect.bottom)
          ..lineTo(bladeRect.left, bladeRect.bottom)
          ..lineTo(bladeRect.left, bladeRect.top)
          ..close();
        canvas.drawPath(bladePath, metalPaint(bladeRect.inflate(2)));
        canvas.drawPath(
            bladePath,
            Paint()
              ..color = Colors.blueGrey.shade700.withValues(alpha: 0.7)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0);
        canvas.drawLine(Offset(fist.dx, bladeRect.top),
            Offset(fist.dx, bladeRect.bottom),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.6)
              ..strokeWidth = 0.9);
        // Golden cross-guard + grip
        drawPlasticRect(
            canvas,
            Rect.fromLTWH(fist.dx - w * 0.045, fist.dy - h * 0.032,
                w * 0.09, h * 0.014),
            const Color(0xFFD4A017),
            2,
            sheen: false);
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
      case 'cetro real':
        // Vara dorada con gema rosa y destello
        drawPlasticRect(
            canvas,
            Rect.fromLTWH(fist.dx - w * 0.010, fist.dy - h * 0.135,
                w * 0.020, h * 0.135),
            const Color(0xFFD4A017),
            2,
            sheen: false);
        drawPlasticSphere(canvas, Offset(fist.dx, fist.dy - h * 0.150),
            w * 0.034, Colors.pink.shade300);
        drawStar4(canvas, Offset(fist.dx, fist.dy - h * 0.150), w * 0.055,
            Paint()..color = Colors.white.withValues(alpha: 0.55));
      case 'globo corazón':
        // Cuerda + globo con forma de corazón
        final heartC = Offset(fist.dx + w * 0.025, fist.dy - h * 0.150);
        canvas.drawLine(
            Offset(fist.dx, fist.dy - fistR * 0.4),
            Offset(heartC.dx, heartC.dy + w * 0.05),
            Paint()
              ..color = Colors.grey.shade500
              ..strokeWidth = 1.2);
        final s = w * 0.075;
        final heart = Path()
          ..moveTo(heartC.dx, heartC.dy + s * 0.62)
          ..cubicTo(heartC.dx - s * 1.10, heartC.dy - s * 0.18,
              heartC.dx - s * 0.50, heartC.dy - s * 0.95, heartC.dx,
              heartC.dy - s * 0.30)
          ..cubicTo(heartC.dx + s * 0.50, heartC.dy - s * 0.95,
              heartC.dx + s * 1.10, heartC.dy - s * 0.18, heartC.dx,
              heartC.dy + s * 0.62)
          ..close();
        drawShadedPath(canvas, heart, Colors.pink.shade400);
        canvas.drawCircle(
            Offset(heartC.dx - s * 0.30, heartC.dy - s * 0.35), s * 0.16,
            Paint()..color = Colors.white.withValues(alpha: 0.7));

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
        canvas.drawPath(
            shield,
            metalPaint(Rect.fromCenter(
                center: fist, width: w * 0.14, height: h * 0.12)));
        canvas.drawPath(
            shield,
            Paint()
              ..color = Colors.blueGrey.shade800
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6);
        // Heraldic center boss
        drawPlasticSphere(canvas, Offset(fist.dx, fist.dy - h * 0.005),
            w * 0.022, const Color(0xFFD4A017));
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
      case 'peluche':
        // Osito de peluche abrazado junto al puño
        final brown = Colors.brown.shade400;
        final tc = Offset(fist.dx - w * 0.01, fist.dy + fistR * 1.6);
        // Patitas
        for (final px in [-1, 1]) {
          drawPlasticSphere(canvas,
              Offset(tc.dx + px * w * 0.032, tc.dy + w * 0.040), w * 0.018, brown);
        }
        // Cuerpo y cabeza
        drawPlasticSphere(canvas, Offset(tc.dx, tc.dy + w * 0.012), w * 0.042, brown);
        final headC = Offset(tc.dx, tc.dy - w * 0.048);
        for (final ex in [-1, 1]) {
          drawPlasticSphere(canvas,
              Offset(headC.dx + ex * w * 0.028, headC.dy - w * 0.026), w * 0.014, brown);
        }
        drawPlasticSphere(canvas, headC, w * 0.034, brown);
        // Hocico y ojos
        canvas.drawCircle(Offset(headC.dx, headC.dy + w * 0.008), w * 0.016,
            Paint()..color = const Color(0xFFD2B48C));
        final eye = Paint()..color = Colors.black87;
        canvas.drawCircle(Offset(headC.dx - w * 0.012, headC.dy - w * 0.006), 1.1, eye);
        canvas.drawCircle(Offset(headC.dx + w * 0.012, headC.dy - w * 0.006), 1.1, eye);
      case 'espejo':
        // Espejo de mano con marco dorado
        final gold = const Color(0xFFD4A017);
        drawPlasticRect(
            canvas,
            Rect.fromLTWH(fist.dx - w * 0.008, fist.dy - h * 0.055,
                w * 0.016, h * 0.05),
            gold,
            2,
            sheen: false);
        final mirrorC = Offset(fist.dx, fist.dy - h * 0.095);
        canvas.drawCircle(mirrorC, w * 0.042, Paint()..color = gold);
        canvas.drawCircle(mirrorC, w * 0.033,
            Paint()..color = Colors.lightBlue.shade100);
        // Reflejo diagonal
        canvas.drawLine(
            Offset(mirrorC.dx - w * 0.016, mirrorC.dy + w * 0.014),
            Offset(mirrorC.dx + w * 0.014, mirrorC.dy - w * 0.016),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.85)
              ..strokeWidth = 2.0);
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
        final r = hs * 0.14;
        for (var i = 0; i < 5; i++) {
          drawPlasticSphere(
              canvas, Offset(hx + hs * (0.1 + i * 0.2), hy - hs * 0.02), r, color);
        }
        drawPlasticSphere(canvas, Offset(hx, hy + hs * 0.14), r * 0.9, color);
        drawPlasticSphere(canvas, Offset(hx + hs, hy + hs * 0.14), r * 0.9, color);
      case HairStyle.afro:
        drawPlasticSphere(
            canvas, Offset(hx + hs / 2, hy - hs * 0.02), hs * 0.42, color);
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
        // La cola larga se dibuja en _drawLongHairOverlay, sobre el torso
      case HairStyle.braids:
        _drawRoundRect(canvas, Rect.fromLTWH(hx - 2, hy - hs * 0.12, hs + 4, hs * 0.35), color, 6);
        // Las trenzas largas se dibujan en _drawLongHairOverlay, sobre el torso
      case HairStyle.shaved:
        _drawRoundRect(canvas,
            Rect.fromLTWH(hx - 1, hy - hs * 0.05, hs + 2, hs * 0.16), color, 4);
      case HairStyle.messy:
        // Pelo revuelto: mechones esféricos desordenados de distintos tamaños
        final tufts = [
          (0.12, -0.06, 0.15),
          (0.34, -0.14, 0.17),
          (0.58, -0.10, 0.16),
          (0.80, -0.04, 0.14),
          (0.02, 0.10, 0.12),
          (0.96, 0.10, 0.12),
          (0.46, -0.02, 0.15),
        ];
        for (final (tx, ty, tr) in tufts) {
          drawPlasticSphere(
              canvas, Offset(hx + hs * tx, hy + hs * ty), hs * tr, color);
        }
      case HairStyle.swept:
        // Flequillo barrido hacia un lado, con caída sobre la sien derecha
        final sweep = Path()
          ..moveTo(hx - hs * 0.06, hy + hs * 0.28)
          ..quadraticBezierTo(hx - hs * 0.08, hy - hs * 0.14, hx + hs * 0.30,
              hy - hs * 0.16)
          ..quadraticBezierTo(hx + hs * 0.85, hy - hs * 0.20,
              hx + hs * 1.08, hy + hs * 0.10)
          ..lineTo(hx + hs * 1.02, hy + hs * 0.42)
          ..quadraticBezierTo(hx + hs * 0.94, hy + hs * 0.16,
              hx + hs * 0.72, hy + hs * 0.14)
          ..quadraticBezierTo(hx + hs * 0.40, hy + hs * 0.20, hx + hs * 0.16,
              hy + hs * 0.12)
          ..quadraticBezierTo(hx + hs * 0.04, hy + hs * 0.16, hx - hs * 0.06,
              hy + hs * 0.28)
          ..close();
        drawShadedPath(canvas, sweep, color);
      case HairStyle.fringe:
        // Casquete con flequillo dentado sobre la frente
        _drawRoundRect(canvas,
            Rect.fromLTWH(hx - 2, hy - hs * 0.12, hs + 4, hs * 0.22), color, 6);
        // Flequillo lateral sólido con corte diagonal (estilo anime)
        final fringe = Path()
          ..moveTo(hx - 2, hy + hs * 0.06)
          ..lineTo(hx - 2, hy + hs * 0.30)
          ..quadraticBezierTo(
              hx + hs * 0.16, hy + hs * 0.38, hx + hs * 0.34, hy + hs * 0.32)
          ..lineTo(hx + hs * 0.68, hy + hs * 0.12)
          ..lineTo(hx + hs + 2, hy + hs * 0.18)
          ..lineTo(hx + hs + 2, hy + hs * 0.06)
          ..close();
        canvas.drawPath(fringe, Paint()..color = color);
        // Mechón suelto sobre la frente
        final lock = Path()
          ..moveTo(hx + hs * 0.52, hy + hs * 0.21)
          ..lineTo(hx + hs * 0.60, hy + hs * 0.36)
          ..lineTo(hx + hs * 0.68, hy + hs * 0.19)
          ..close();
        canvas.drawPath(lock, Paint()..color = color);
        // Patillas
        _drawRoundRect(canvas,
            Rect.fromLTWH(hx - 2, hy + hs * 0.06, hs * 0.12, hs * 0.42), color, 3);
        _drawRoundRect(
            canvas,
            Rect.fromLTWH(hx + hs - hs * 0.12 + 2, hy + hs * 0.06, hs * 0.12,
                hs * 0.42),
            color,
            3);
      case HairStyle.bald:
        break;
    }
  }

  /// Melenas largas (cola de caballo, trenzas) que caen sobre los hombros:
  /// se pintan después del torso y los brazos para que queden por delante.
  void _drawLongHairOverlay(Canvas canvas) {
    if (appearance.headwearType != HeadwearType.hair) return;
    final style = appearance.hairStyle;
    final hs = headSize;
    final hy = headTop;

    if (style == HairStyle.ponytail) {
      final color = hairColorFor(HairStyle.ponytail);
      // Cola larga que cae por el lado derecho hasta el pecho
      final tail = Path()
        ..moveTo(hx + hs * 0.90, hy + hs * 0.14)
        ..quadraticBezierTo(
            hx + hs * 1.26, hy + hs * 0.50, hx + hs * 1.18, hy + hs * 1.02)
        ..quadraticBezierTo(
            hx + hs * 1.13, hy + hs * 1.38, hx + hs * 0.96, hy + hs * 1.55)
        ..quadraticBezierTo(
            hx + hs * 0.90, hy + hs * 1.28, hx + hs * 0.95, hy + hs * 1.00)
        ..quadraticBezierTo(
            hx + hs * 1.00, hy + hs * 0.48, hx + hs * 0.84, hy + hs * 0.22)
        ..close();
      drawShadedPath(canvas, tail, color);
      // Mechón de brillo siguiendo la caída
      canvas.drawPath(
        Path()
          ..moveTo(hx + hs * 0.98, hy + hs * 0.30)
          ..quadraticBezierTo(
              hx + hs * 1.14, hy + hs * 0.70, hx + hs * 1.06, hy + hs * 1.20),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
      // Coletero
      _drawRoundRect(
          canvas,
          Rect.fromLTWH(hx + hs * 0.92, hy + hs * 0.30, hs * 0.26, hs * 0.10),
          Colors.pink.shade400,
          3);
    } else if (style == HairStyle.braids) {
      final color = hairColorFor(HairStyle.braids);
      // Trenzas largas por delante de los hombros, en segmentos
      for (final bx in [hx - hs * 0.02, hx + hs * 1.02]) {
        final drift = bx < w / 2 ? -hs * 0.05 : hs * 0.05;
        for (var i = 0; i < 6; i++) {
          final r = hs * (0.11 - i * 0.008);
          drawPlasticSphere(
              canvas,
              Offset(bx + drift * (i / 5), hy + hs * (0.28 + i * 0.20)),
              r,
              color);
        }
        // Lazo al final de la trenza
        _drawRoundRect(
            canvas,
            Rect.fromLTWH(bx + drift - hs * 0.085, hy + hs * 1.36,
                hs * 0.17, hs * 0.07),
            Colors.red.shade400,
            2);
        // Puntita
        drawPlasticSphere(canvas,
            Offset(bx + drift, hy + hs * 1.50), hs * 0.06, color);
      }
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
        drawShadedPath(canvas, leftHorn, horn.color);
        drawShadedPath(canvas, rightHorn, horn.color);
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
        drawShadedPath(canvas, cone, color);
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
        drawShadedPath(canvas, path, color);
        drawPlasticSphere(canvas, Offset(hx + hs * 0.5, hy - hs * 0.06),
            hs * 0.05, Colors.red.shade600);
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
        drawShadedPath(canvas, path, color);
        drawPlasticSphere(canvas, Offset(hx + hs * 0.5, hy - hs * 0.08),
            hs * 0.045, Colors.pink.shade300);
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
        drawShadedPath(canvas, tricorn, color);
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

    // Pupil with a white specular glint — the classic LEGO face detail
    void pupil(Offset c, double r) {
      canvas.drawCircle(c, r, blackPaint);
      canvas.drawCircle(Offset(c.dx - r * 0.30, c.dy - r * 0.32), r * 0.30,
          Paint()..color = Colors.white.withValues(alpha: 0.85));
    }

    if (appearance.eyes == EyeStyle.laser) {
      for (final x in [eyeLX, eyeRX]) {
        canvas.drawCircle(Offset(x, eyeY), eyeR * 1.6,
            Paint()..color = Colors.red.withValues(alpha: 0.30));
        canvas.drawCircle(Offset(x, eyeY), eyeR, Paint()..color = Colors.red);
        canvas.drawCircle(Offset(x, eyeY), eyeR * 0.45,
            Paint()..color = Colors.orange.shade200);
      }
    } else if (appearance.eyes == EyeStyle.robot) {
      for (final x in [eyeLX, eyeRX]) {
        final r = Rect.fromCenter(
            center: Offset(x, eyeY), width: eyeR * 2.2, height: eyeR * 1.4);
        canvas.drawRect(r.inflate(1.5), Paint()..color = Colors.grey.shade800);
        canvas.drawRect(r, Paint()..color = Colors.cyan);
        canvas.drawRect(
            Rect.fromLTWH(r.left, r.top, r.width, r.height * 0.35),
            Paint()..color = Colors.white.withValues(alpha: 0.45));
      }
    } else if (appearance.eyes == EyeStyle.starry) {
      canvas.drawCircle(Offset(eyeLX, eyeY), eyeR * 1.5, Paint()..color = Colors.yellow.withValues(alpha: 0.5));
      canvas.drawCircle(Offset(eyeRX, eyeY), eyeR * 1.5, Paint()..color = Colors.yellow.withValues(alpha: 0.5));
      pupil(Offset(eyeLX, eyeY), eyeR);
      pupil(Offset(eyeRX, eyeY), eyeR);
    } else if (appearance.eyes == EyeStyle.surprised) {
      pupil(Offset(eyeLX, eyeY), eyeR * 1.5);
      pupil(Offset(eyeRX, eyeY), eyeR * 1.5);
    } else if (appearance.eyes == EyeStyle.angry) {
      pupil(Offset(eyeLX, eyeY), eyeR);
      pupil(Offset(eyeRX, eyeY), eyeR);
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
      pupil(Offset(eyeLX, eyeY), eyeR);
      // Right eye winked (curved line)
      final winkPath = Path()
        ..moveTo(eyeRX - eyeR, eyeY)
        ..quadraticBezierTo(eyeRX, eyeY - eyeR * 0.8, eyeRX + eyeR, eyeY);
      canvas.drawPath(winkPath, strokePaint);
    } else if (appearance.eyes == EyeStyle.determined) {
      // Mirada de esfuerzo: ojos entrecerrados con cejas rectas inclinadas
      for (final x in [eyeLX, eyeRX]) {
        canvas.drawCircle(Offset(x, eyeY), eyeR * 0.92, blackPaint);
        // Párpado inferior que sube (esfuerzo)
        canvas.drawRect(
            Rect.fromLTWH(x - eyeR * 1.2, eyeY + eyeR * 0.25, eyeR * 2.4,
                eyeR * 1.0),
            Paint()..color = skinColor);
        canvas.drawCircle(Offset(x - eyeR * 0.25, eyeY - eyeR * 0.30),
            eyeR * 0.24, Paint()..color = Colors.white.withValues(alpha: 0.85));
      }
      // Cejas rectas hacia el centro
      canvas.drawLine(Offset(eyeLX - eyeR * 1.1, eyeY - eyeR * 2.2),
          Offset(eyeLX + eyeR * 1.0, eyeY - eyeR * 1.5), strokePaint);
      canvas.drawLine(Offset(eyeRX - eyeR * 1.0, eyeY - eyeR * 1.5),
          Offset(eyeRX + eyeR * 1.1, eyeY - eyeR * 2.2), strokePaint);
    } else if (appearance.eyes == EyeStyle.crying) {
      pupil(Offset(eyeLX, eyeY), eyeR);
      pupil(Offset(eyeRX, eyeY), eyeR);
      // Tears with a glossy highlight
      final tearPaint = Paint()..color = Colors.lightBlue.shade300;
      for (final t in [
        Offset(eyeLX - eyeR * 0.2, eyeY + eyeR * 2.5),
        Offset(eyeRX + eyeR * 0.2, eyeY + eyeR * 2.5),
      ]) {
        canvas.drawOval(
            Rect.fromCenter(center: t, width: eyeR * 0.7, height: eyeR * 1.8),
            tearPaint);
        canvas.drawCircle(Offset(t.dx - eyeR * 0.12, t.dy - eyeR * 0.35),
            eyeR * 0.16, Paint()..color = Colors.white.withValues(alpha: 0.8));
      }
    } else {
      // happy — default
      pupil(Offset(eyeLX, eyeY), eyeR);
      pupil(Offset(eyeRX, eyeY), eyeR);
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
    drawPlasticRect(canvas, rect, color, radius);
  }

  @override
  bool shouldRepaint(_CharacterPainter oldDelegate) =>
      oldDelegate.appearance != appearance;
}
