import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/features/runner/domain/entities/continue_cost.dart';

/// Pruebas de la política de coste para retomar la carrera (revive). Es una
/// función pura: mismas entradas → mismas salidas, sin estado ni azar.
void main() {
  group('continueOfferFor — moneda por continuación', () {
    test('las dos primeras continuaciones se pagan con monedas', () {
      expect(continueOfferFor(0).currency, ContinueCurrency.coins,
          reason: 'La 1.ª continuación debe ser en monedas (asequible).');
      expect(continueOfferFor(1).currency, ContinueCurrency.coins,
          reason: 'La 2.ª continuación sigue en monedas.');
    });

    test('de la tercera en adelante se paga con gemas', () {
      for (var n = 2; n < 8; n++) {
        expect(continueOfferFor(n).currency, ContinueCurrency.gems,
            reason: 'La continuación #${n + 1} debe pasar a gemas.');
      }
    });
  });

  group('continueOfferFor — importes de la tabla', () {
    test('valores concretos esperados', () {
      expect(continueOfferFor(0).amount, 100);
      expect(continueOfferFor(1).amount, 250);
      expect(continueOfferFor(2).amount, 20);
      expect(continueOfferFor(3).amount, 40);
      expect(continueOfferFor(4).amount, 80);
      expect(continueOfferFor(5).amount, 160);
    });

    test('el coste en monedas es estrictamente creciente', () {
      expect(continueOfferFor(1).amount, greaterThan(continueOfferFor(0).amount),
          reason: 'Cada continuación en monedas debe costar más que la previa.');
    });

    test('el coste en gemas crece hasta topar en kContinueMaxGemCost', () {
      // Índices de gemas: 2,3,4,5,6… → 20,40,80,160,320,320…
      for (var n = 2; n < 7; n++) {
        expect(
          continueOfferFor(n + 1).amount,
          greaterThanOrEqualTo(continueOfferFor(n).amount),
          reason: 'El coste en gemas nunca debe bajar.',
        );
      }
      expect(continueOfferFor(6).amount, kContinueMaxGemCost,
          reason: 'Debe alcanzar el tope.');
      expect(continueOfferFor(20).amount, kContinueMaxGemCost,
          reason: 'El coste en gemas no supera el tope por muchas que sean.');
    });
  });

  group('continueOfferFor — robustez', () {
    test('es determinista (misma entrada → misma salida)', () {
      for (var n = 0; n < 10; n++) {
        final a = continueOfferFor(n);
        final b = continueOfferFor(n);
        expect(a.currency, b.currency);
        expect(a.amount, b.amount);
      }
    });

    test('un contador negativo se trata como la primera continuación', () {
      expect(continueOfferFor(-5).currency, continueOfferFor(0).currency);
      expect(continueOfferFor(-5).amount, continueOfferFor(0).amount);
    });
  });
}
