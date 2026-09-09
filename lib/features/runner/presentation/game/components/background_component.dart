import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../../../domain/entities/world_config.dart';
import '../brix_run_game.dart';

class BackgroundComponent extends PositionComponent
    with HasGameReference<BrixRunGame> {
  final String worldId;

  double _groundScroll = 0.0;
  double _buildingScroll = 0.0;

  late List<_Building> _buildings;

  // Estrellas del cielo de galaxy, generadas una sola vez (ver _drawSkyDecorations).
  List<_Star>? _galaxyStars;
  final Paint _starPaint = Paint();

  /// Paleta del mundo, preparada una sola vez (ver [_BackgroundPalette]).
  late final _BackgroundPalette _p = _BackgroundPalette(colorsFor(worldId));

  List<_Star> _buildGalaxyStars() {
    final rng = Random(77);
    // Mismo orden de consumo del RNG que la versión previa por-frame (fx, fy,
    // r, alpha) para que las estrellas queden en idénticas posiciones.
    return List.generate(60, (_) {
      final fx = rng.nextDouble();
      final fy = rng.nextDouble();
      final r = rng.nextDouble() * 1.6 + 0.4;
      final alpha = rng.nextDouble() * 0.5 + 0.4;
      return _Star(fx: fx, fy: fy, r: r, alpha: alpha);
    });
  }

  BackgroundComponent({required this.worldId})
      : super(position: Vector2.zero(), priority: -10);

  @override
  Future<void> onLoad() async {
    final rng = Random(worldId.hashCode);
    _buildings = List.generate(14, (_) => _Building(rng));
  }

  @override
  void update(double dt) {
    _groundScroll += game.depthRate * dt;
    _buildingScroll += game.speed * 0.36 * dt;
  }

  @override
  void render(Canvas canvas) {
    final w = game.size.x;
    final h = game.size.y;
    final c = _p;
    final hy = game.horizonY;
    final py = game.playerBaseY;
    final vx = game.vanishX;
    final sep = game.laneSep;

    // 1 — Sky
    _drawSky(canvas, w, hy, c);

    // 2 — City silhouette behind track (above horizon)
    _drawCitySilhouette(canvas, w, hy, vx, c);

    // 3 — Sky decorations (stars, moon, etc.)
    _drawSkyDecorations(canvas, w, h, hy, c);

    // 4 — Ground plane with perspective grid
    _drawGround(canvas, w, h, hy, py, vx, sep, c);
  }

  // ── Sky ─────────────────────────────────────────────────────────────────────

  void _drawSky(Canvas canvas, double w, double hy, _BackgroundPalette c) {
    canvas.drawRect(Rect.fromLTWH(0, 0, w, hy), c.sky);
    // Horizon warm glow
    canvas.drawRect(Rect.fromLTWH(0, hy * 0.70, w, hy * 0.30), c.horizonGlow);
  }

  // ── City silhouette scrolling above horizon ──────────────────────────────────

  void _drawCitySilhouette(
      Canvas canvas, double w, double hy, double vx, _BackgroundPalette c) {
    final scrolled = _buildingScroll % (w * 0.85);

    for (final b in _buildings) {
      final rawX = (b.relX * w * 0.85 - scrolled) % (w * 0.85);

      // Skip buildings near the center vanishing corridor
      final distFromCenter = (rawX - vx).abs();
      if (distFromCenter < w * 0.10) continue;

      final bh = b.heightFraction * hy * 0.80 + hy * 0.10;
      final bw = 24.0 + b.widthFraction * 34.0;
      final bx = rawX - bw / 2;

      // Building body
      canvas.drawRect(Rect.fromLTWH(bx, hy - bh, bw, bh), c.building);

      // Windows
      _drawWindows(canvas, bx, hy - bh, bw, bh, c);

      // World-specific roof
      _drawRoof(canvas, bx, hy - bh, bw, c);
    }
  }

  void _drawWindows(Canvas canvas, double bx, double bTop, double bw,
      double bh, _BackgroundPalette c) {
    if (bw < 12 || bh < 18) return;
    final cols = (bw / 13).floor().clamp(1, 3);
    final rows = (bh / 18).floor().clamp(1, 7);
    for (int r = 0; r < rows; r++) {
      for (int col = 0; col < cols; col++) {
        canvas.drawRect(
          Rect.fromLTWH(bx + col * (bw / cols) + 3, bTop + r * 18 + 5, 7, 10),
          c.window,
        );
      }
    }
  }

  void _drawRoof(Canvas canvas, double bx, double bTop, double bw,
      _BackgroundPalette c) {
    switch (worldId) {
      case 'medieval':
        final cols = (bw / 10).floor();
        for (int i = 0; i < cols; i++) {
          if (i.isEven) {
            canvas.drawRect(
                Rect.fromLTWH(bx + i * 10, bTop - 10, 8, 10), c.building);
          }
        }
      case 'dark_city':
        final cx = bx + bw / 2;
        final spire = Path()
          ..moveTo(cx, bTop - 20)
          ..lineTo(cx - 4, bTop)
          ..lineTo(cx + 4, bTop)
          ..close();
        canvas.drawPath(spire, c.spire);
      case 'galaxy':
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(bx + bw / 2, bTop),
              width: bw * 0.70,
              height: bw * 0.25),
          c.halo,
        );
      case 'robot_city':
        canvas.drawRect(
            Rect.fromLTWH(bx + bw / 2 - 1.5, bTop - 16, 3, 16), c.building);
        canvas.drawCircle(Offset(bx + bw / 2, bTop - 18), 4, c.beacon);
      case 'jungle':
        canvas.drawCircle(
            Offset(bx + bw / 2, bTop - 12), bw * 0.42, c.treetop);
      case 'tundra':
        final mPath = Path()
          ..moveTo(bx, bTop)
          ..lineTo(bx + bw / 2, bTop - bw * 0.55)
          ..lineTo(bx + bw, bTop)
          ..close();
        canvas.drawPath(mPath, c.snow);
      default:
        break;
    }
  }

  // ── Sky decorations ──────────────────────────────────────────────────────────

  void _drawSkyDecorations(
      Canvas canvas, double w, double h, double hy, _BackgroundPalette c) {
    switch (worldId) {
      case 'galaxy':
        // Antes se creaba un Random(77) y 60 círculos CADA frame. Las estrellas
        // son fijas: se generan una sola vez (mismo orden de RNG → idéntico) en
        // fracciones independientes de la resolución y se reutiliza un Paint.
        final stars = _galaxyStars ??= _buildGalaxyStars();
        for (final s in stars) {
          _starPaint.color = Colors.white.withValues(alpha: s.alpha);
          canvas.drawCircle(Offset(s.fx * w, s.fy * hy * 0.95), s.r, _starPaint);
        }
      case 'dark_city':
        canvas.drawCircle(Offset(w * 0.80, h * 0.11), 24, c.moon);
        canvas.drawCircle(Offset(w * 0.84, h * 0.09), 18, c.sky);
      case 'tundra':
        for (int i = 0; i < _auroraBands.length; i++) {
          canvas.drawRect(
            Rect.fromLTWH(0, hy * (0.10 + i * 0.10), w, hy * 0.05),
            _auroraBands[i],
          );
        }
      case 'ocean':
        for (int i = 0; i < 6; i++) {
          final rx = (i * w / 6 + (_buildingScroll * 0.04) % (w / 6));
          canvas.drawRect(Rect.fromLTWH(rx, 0, 16, hy * 0.90), c.sunRay);
        }
      case 'jungle':
        for (int i = 0; i < 5; i++) {
          final cx = (i * w * 0.22 - _buildingScroll * 0.06) % (w + 40) - 20;
          canvas.drawCircle(Offset(cx, hy * 0.72), 24, c.canopy);
        }
      default:
        break;
    }
  }

  // ── Perspective ground ───────────────────────────────────────────────────────

  void _drawGround(Canvas canvas, double w, double h, double hy, double py,
      double vx, double sep, _BackgroundPalette c) {
    // Base ground fill
    canvas.drawRect(Rect.fromLTWH(0, hy, w, h - hy), c.ground);

    // Track surface (slightly different shade)
    final trackPath = Path()
      ..moveTo(vx, hy)
      ..lineTo(vx + sep * 1.60, h)
      ..lineTo(vx - sep * 1.60, h)
      ..close();
    canvas.drawPath(trackPath, c.track);

    // Horizon accent
    canvas.drawRect(Rect.fromLTWH(0, hy - 1.5, w, 3), c.horizonAccent);

    // Scrolling cross-lines (depth motion grid)
    _drawCrossLines(canvas, hy, py, vx, sep, c);

    // Rail perspective lines (converging to vanish point)
    _drawRailLines(canvas, hy, py, vx, sep, c);
  }

  void _drawCrossLines(Canvas canvas, double hy, double py, double vx,
      double sep, _BackgroundPalette c) {
    const dz = 0.135;
    final phase = _groundScroll % dz;

    for (double base = 0.0; base <= 1.0 + dz; base += dz) {
      final t = (base - phase).clamp(0.0, 1.5);
      if (t < 0.02 || t > 1.0) continue;
      final ly = hy + (py - hy) * t;
      final halfW = sep * 1.60 * t;

      // Cross line
      canvas.drawLine(Offset(vx - halfW, ly), Offset(vx + halfW, ly), c.gridLine);

      // Brix stud dots on every other line
      if ((base / dz).round().isEven) {
        final dotR = 3.5 * t;
        // El desplazamiento de cada carril se calcula (−sep, 0, +sep) en vez de
        // indexar una lista: aquí se construía una lista nueva por carril, por
        // línea y por frame.
        for (int lane = -1; lane <= 1; lane++) {
          canvas.drawCircle(
              Offset(vx + lane * sep * t, ly - dotR), dotR, c.stud);
        }
      }
    }
  }

  void _drawRailLines(Canvas canvas, double hy, double py, double vx,
      double sep, _BackgroundPalette c) {
    // Cuatro raíles: los de fuera marcan el borde de la pista y los de dentro
    // separan los carriles. Antes se construía una lista de tuplas —con sus dos
    // `Paint`— en cada frame solo para recorrerla.
    final top = Offset(vx, hy);
    final bottomY = py + (py * 0.26);
    canvas.drawLine(top, Offset(vx - sep * 1.60, bottomY), c.railOuter);
    canvas.drawLine(top, Offset(vx - sep * 0.53, bottomY), c.railInner);
    canvas.drawLine(top, Offset(vx + sep * 0.53, bottomY), c.railInner);
    canvas.drawLine(top, Offset(vx + sep * 1.60, bottomY), c.railOuter);
  }
}

/// Estrella fija del cielo de galaxy en fracciones de pantalla (0–1) para ser
/// independiente de la resolución; se genera una sola vez.
class _Star {
  final double fx;
  final double fy;
  final double r;
  final double alpha;
  const _Star({
    required this.fx,
    required this.fy,
    required this.r,
    required this.alpha,
  });
}

class _Building {
  final double relX;
  final double heightFraction;
  final double widthFraction;

  _Building(Random rng)
      : relX = rng.nextDouble(),
        heightFraction = 0.15 + rng.nextDouble() * 0.75,
        widthFraction = rng.nextDouble();
}

/// Los `Paint` del fondo, preparados **una sola vez** por partida.
///
/// El fondo se redibuja entero en cada frame —cielo, catorce edificios con sus
/// ventanas y tejados, el suelo con su rejilla y sus raíles— y todos sus
/// colores salen de [WorldColors], que no cambia mientras se juega. Crearlos
/// dentro del `render` eran unas cuarenta instancias de `Paint` y otras tantas
/// de `Color` por frame (cada `withValues` construye un color nuevo), solo para
/// tirarlas acto seguido y volver a crear las mismas en el frame siguiente.
///
/// Aquí se construyen al montar el componente y se reutilizan. Son de solo
/// lectura una vez creados: ninguno se muta durante el dibujo, así que no hay
/// riesgo de que un uso se lleve el estado de otro.
class _BackgroundPalette {
  _BackgroundPalette(WorldColors c)
      : sky = Paint()..color = c.sky,
        horizonGlow = Paint()..color = c.accent.withValues(alpha: 0.09),
        building = Paint()..color = c.midground,
        window = Paint()..color = c.accent.withValues(alpha: 0.30),
        spire = Paint()..color = c.accent.withValues(alpha: 0.80),
        halo = Paint()..color = c.accent.withValues(alpha: 0.25),
        beacon = Paint()..color = c.accent,
        treetop = Paint()
          ..color = Colors.green.shade700.withValues(alpha: 0.75),
        snow = Paint()..color = Colors.white.withValues(alpha: 0.55),
        moon = Paint()..color = const Color(0xFFFFF8DC),
        sunRay = Paint()..color = Colors.white.withValues(alpha: 0.04),
        canopy = Paint()..color = Colors.green.shade900.withValues(alpha: 0.45),
        ground = Paint()..color = c.ground,
        track = Paint()..color = c.midground.withValues(alpha: 0.38),
        horizonAccent = Paint()..color = c.accent.withValues(alpha: 0.50),
        gridLine = Paint()
          ..color = c.accent.withValues(alpha: 0.16)
          ..strokeWidth = 1.5,
        stud = Paint()..color = c.accent.withValues(alpha: 0.09),
        railOuter = Paint()
          ..color = c.accent.withValues(alpha: 0.48)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke,
        railInner = Paint()
          ..color = Colors.white.withValues(alpha: 0.20)
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke;

  // Cielo y siluetas
  final Paint sky;
  final Paint horizonGlow;
  final Paint building;
  final Paint window;

  // Remates de tejado, cada uno de su mundo
  final Paint spire; // dark_city
  final Paint halo; // galaxy
  final Paint beacon; // robot_city
  final Paint treetop; // jungle
  final Paint snow; // tundra

  // Decoración del cielo
  final Paint moon; // dark_city
  final Paint sunRay; // ocean
  final Paint canopy; // jungle

  // Suelo
  final Paint ground;
  final Paint track;
  final Paint horizonAccent;
  final Paint gridLine;
  final Paint stud;
  final Paint railOuter;
  final Paint railInner;
}

/// Bandas de la aurora de tundra. Constantes y sin relación con el mundo, así
/// que se preparan una vez para todo el proceso.
final _auroraBands = <Paint>[
  Paint()..color = Colors.green.withValues(alpha: 0.10),
  Paint()..color = Colors.purple.withValues(alpha: 0.10),
  Paint()..color = Colors.teal.withValues(alpha: 0.10),
];
