import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lego_custom_character/features/home/presentation/widgets/roulette_button.dart';

/// Lee la rotación actual de la rueda desde el painter montado.
double _rotationOf(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.byKey(RouletteButton.wheelKey),
  );
  return (paint.painter! as RouletteWheelPainter).rotation;
}

Future<void> _pumpButton(WidgetTester tester, {required bool available}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: RouletteButton(available: available, onTap: () {}),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('disponible: la rueda gira y acaba dando 2 vueltas', (
    tester,
  ) async {
    await _pumpButton(tester, available: true);

    expect(_rotationOf(tester), 0.0);

    // Durante la fase de giro (primer 55% de 4200ms = 2310ms) avanza.
    await tester.pump(const Duration(milliseconds: 600));
    final mid = _rotationOf(tester);
    expect(mid, greaterThan(0.0), reason: 'la rueda debe estar girando');

    await tester.pump(const Duration(milliseconds: 600));
    expect(_rotationOf(tester), greaterThan(mid));

    // Pasada la fase de giro (65% de 3600ms = 2340ms) se queda quieta.
    await tester.pump(const Duration(milliseconds: 1200));
    final settled = _rotationOf(tester);
    expect(settled, closeTo(2 * 2 * 3.141592653589793, 0.001));

    await tester.pump(const Duration(milliseconds: 500));
    expect(_rotationOf(tester), settled, reason: 'debe reposar antes de repetir');
  });

  testWidgets('ya girada: la rueda no se mueve', (tester) async {
    await _pumpButton(tester, available: false);

    expect(_rotationOf(tester), 0.0);
    await tester.pump(const Duration(milliseconds: 600));
    expect(_rotationOf(tester), 0.0);
    await tester.pump(const Duration(milliseconds: 2000));
    expect(_rotationOf(tester), 0.0);
  });

  testWidgets('al pasar a disponible arranca la animación', (tester) async {
    await _pumpButton(tester, available: false);
    await tester.pump(const Duration(milliseconds: 600));
    expect(_rotationOf(tester), 0.0);

    await _pumpButton(tester, available: true);
    await tester.pump(const Duration(milliseconds: 600));
    expect(_rotationOf(tester), greaterThan(0.0));
  });
}
