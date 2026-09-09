import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/features/character_editor/domain/entities/character.dart';
import 'package:run_for_win/features/character_editor/presentation/widgets/character_preview.dart';

/// El painter del minifigure es caro (cientos de operaciones de dibujo por
/// figura) y casi siempre está quieto mientras su alrededor se mueve: confeti
/// en la pantalla de fin de partida, la ruleta girando en el inicio.
///
/// Sin un límite de repintado propio, cuando un hermano se repinta Flutter sube
/// hasta el límite más cercano y vuelve a ejecutar el `paint` de todo el
/// subárbol, minifigure incluido, en cada frame de la animación.
///
/// Esto no comprueba que el widget esté ahí: **mide** los repintados que se
/// ahorran, con la métrica que el propio `RenderRepaintBoundary` lleva para
/// eso (`debugAsymmetricPaintCount` cuenta las veces que el entorno se repintó
/// SIN repintar este subárbol).

/// Pinta algo trivial pero distinto en cada frame, como el confeti: obliga a
/// repintar, y anota cuántas veces lo han llamado.
class _AnimatedSiblingPainter extends CustomPainter {
  _AnimatedSiblingPainter(this.t);
  final double t;

  static int paints = 0;

  @override
  void paint(Canvas canvas, Size size) {
    paints++;
    canvas.drawCircle(Offset(size.width * t, 10), 4, Paint());
  }

  @override
  bool shouldRepaint(_AnimatedSiblingPainter old) => old.t != t;
}

/// Reproduce la situación real: el minifigure y una animación como hermanos
/// dentro del mismo `Stack`.
class _Scene extends StatefulWidget {
  const _Scene();
  @override
  State<_Scene> createState() => _SceneState();
}

class _SceneState extends State<_Scene> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          const CharacterPreview(
            appearance: CharacterAppearance(),
            size: 120,
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) => CustomPaint(
                painter: _AnimatedSiblingPainter(_c.value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('el minifigure no se repinta cuando su entorno se anima',
      (tester) async {
    await tester.pumpWidget(const _Scene());

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.descendant(
        of: find.byType(CharacterPreview),
        matching: find.byType(RepaintBoundary),
      ),
    );
    boundary.debugResetMetrics();
    _AnimatedSiblingPainter.paints = 0;

    // 20 frames de animación del hermano.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(_AnimatedSiblingPainter.paints, greaterThan(10),
        reason: 'el hermano sí debe estar repintándose en cada frame');
    expect(
      boundary.debugAsymmetricPaintCount,
      greaterThan(10),
      reason: 'cada uno de esos repintados debe haberse ahorrado el minifigure',
    );
    expect(boundary.debugSymmetricPaintCount, 0,
        reason: 'nada obligó a redibujar la figura: no cambió su apariencia',
    );
  });

  testWidgets('cambiar la apariencia sí redibuja la figura', (tester) async {
    // La contrapartida: aislar el repintado no puede dejar la figura congelada
    // cuando de verdad cambia (el editor la cambia con cada toque). Se
    // interroga el contrato que decide eso —`shouldRepaint`— sobre los painters
    // que el widget monta de verdad.
    Future<void> pumpWith(CharacterAppearance a) => tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CharacterPreview(appearance: a, size: 120),
          ),
        );

    CustomPainter painter() => tester
        .widget<CustomPaint>(find.descendant(
          of: find.byType(CharacterPreview),
          matching: find.byType(CustomPaint),
        ))
        .painter!;

    await pumpWith(const CharacterAppearance());
    final sinCapa = painter();

    await pumpWith(const CharacterAppearance(hasCape: true));

    expect(painter().shouldRepaint(sinCapa), isTrue,
        reason: 'la capa nueva tiene que llegar al lienzo');
  });
}
