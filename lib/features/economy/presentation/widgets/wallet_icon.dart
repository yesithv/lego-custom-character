import 'package:flutter/material.dart';

/// Ícono de billetera del juego, dibujado a mano (sin dependencias de SVG).
///
/// Estilo caricatura con contorno grueso, inspirado en la referencia: una
/// cartera marrón de la que asoman —cortadas por la boca del bolsillo, así que
/// solo se ve su mitad superior— la moneda 🪙 y la gema 💎 estándar del juego
/// (los mismos emojis que usa el resto de la app: billetera, misiones, tienda…).
///
/// Se usa tanto en el badge del home como en el título de "Mi Billetera" para
/// mantener una sola imagen de billetera en todo el juego.
class WalletIcon extends StatelessWidget {
  final double size;

  const WalletIcon({super.key, this.size = 54});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _WalletPainter()),
    );
  }
}

/// Dibuja la billetera en un lienzo lógico de 100×100 (se escala al tamaño
/// real). La billetera es algo más angosta que el lienzo para dejar aire a los
/// lados.
class _WalletPainter extends CustomPainter {
  const _WalletPainter();

  static const Color _outline = Color(0xFF2F1E10);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100.0;
    // El contenido dibujado ocupa ~y29..y91 del lienzo (moneda/gema que asoman
    // arriba + cuerpo abajo), así que está sesgado hacia abajo. Lo subimos ~10
    // para que quede centrado verticalmente con márgenes simétricos.
    canvas.translate(0, -10 * s);
    Offset p(double x, double y) => Offset(x * s, y * s);
    Paint stroke(Color c, double w,
            {StrokeJoin join = StrokeJoin.round,
            StrokeCap cap = StrokeCap.round}) =>
        Paint()
          ..style = PaintingStyle.stroke
          ..color = c
          ..strokeWidth = w * s
          ..strokeJoin = join
          ..strokeCap = cap;

    void emoji(String glyph, double cx, double cy, double fontSize) {
      final tp = TextPainter(
        text: TextSpan(
          text: glyph,
          style: TextStyle(fontSize: fontSize * s, height: 1.0),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p(cx, cy) - Offset(tp.width / 2, tp.height / 2));
    }

    // Borde superior del bolsillo: por debajo de esta línea la moneda y la
    // gema quedan ocultas → solo se ve su mitad superior.
    const double mouthY = 44;

    // ── Pared trasera (reborde marrón claro sobre el bolsillo) ─────────────
    final backRect = Rect.fromLTWH(13 * s, 36 * s, 74 * s, 54 * s);
    final back = RRect.fromRectAndRadius(backRect, Radius.circular(12 * s));
    canvas.drawRRect(back, Paint()..color = const Color(0xFFA9743F));
    canvas.drawRRect(back, stroke(_outline, 3.6));

    // ── Moneda 🪙 y gema 💎 asomando (media moneda / media gema) ───────────
    // Se dibujan antes que el bolsillo frontal para que este tape su mitad
    // inferior. Son los mismos emojis que usa el resto de la app. Orden de
    // izquierda a derecha: primero la moneda, luego la gema.
    emoji('🪙', 37, mouthY.toDouble(), 30);
    emoji('💎', 64, mouthY.toDouble(), 26);

    // ── Bolsillo frontal (tapa la mitad inferior de moneda y gema) ────────
    final frontRect = Rect.fromLTWH(13 * s, mouthY * s, 74 * s, 46 * s);
    final front = RRect.fromRectAndRadius(frontRect, Radius.circular(11 * s));
    canvas.drawRRect(
      front,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9A6638), Color(0xFF7C4E28)],
        ).createShader(frontRect),
    );
    canvas.drawRRect(front, stroke(_outline, 3.6));

    // Boca del bolsillo (línea curva bajo el borde)
    final mouth = Path()
      ..moveTo(20 * s, 55 * s)
      ..quadraticBezierTo(50 * s, 51 * s, 80 * s, 55 * s);
    canvas.drawPath(mouth, stroke(_outline, 2.4));

    // Broche naranja
    final clasp = RRect.fromRectAndRadius(
        Rect.fromLTWH(62 * s, 66 * s, 17 * s, 12 * s), Radius.circular(4 * s));
    canvas.drawRRect(clasp, Paint()..color = const Color(0xFFF5A623));
    canvas.drawRRect(clasp, stroke(_outline, 2.4));
    canvas.drawCircle(
        p(70.5, 72), 2 * s, Paint()..color = const Color(0xFF8A3D00));

    // Puntada de la esquina inferior izquierda
    final stitch = Path()
      ..moveTo(21 * s, 84 * s)
      ..lineTo(21 * s, 77 * s)
      ..moveTo(21 * s, 84 * s)
      ..lineTo(28 * s, 84 * s);
    canvas.drawPath(stitch, stroke(_outline, 2.2));
  }

  @override
  bool shouldRepaint(covariant _WalletPainter oldDelegate) => false;
}
