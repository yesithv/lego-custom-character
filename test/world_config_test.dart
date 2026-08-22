import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/features/runner/domain/entities/world_config.dart';

/// Edge cases y consistencia de la configuración de mundos: mundos desconocidos
/// deben caer a valores por defecto seguros (nunca reventar), y las tablas de
/// colores y de metros deben cubrir exactamente los mismos mundos.
void main() {
  const knownWorlds = [
    'brix_city', 'medieval', 'galaxy', 'jungle',
    'dark_city', 'ocean', 'tundra', 'robot_city',
  ];

  group('colorsFor', () {
    test('un mundo desconocido cae a brix_city', () {
      expect(colorsFor('no_existe'), same(colorsFor('brix_city')));
    });
    test('cadena vacía cae a brix_city', () {
      expect(colorsFor(''), same(colorsFor('brix_city')));
    });
    test('cada mundo conocido tiene colores propios', () {
      for (final w in knownWorlds) {
        expect(worldConfigs.containsKey(w), isTrue, reason: w);
      }
    });
  });

  group('trackMetersFor', () {
    test('un mundo desconocido cae a 500 m', () {
      expect(trackMetersFor('no_existe'), 500);
    });
    test('valores conocidos', () {
      expect(trackMetersFor('brix_city'), 500);
      expect(trackMetersFor('robot_city'), 1100);
    });
    test('la pista crece (o iguala) de un mundo al siguiente', () {
      var prev = 0;
      for (final w in [
        'brix_city', 'medieval', 'ocean', 'jungle',
        'galaxy', 'tundra', 'dark_city', 'robot_city',
      ]) {
        final m = trackMetersFor(w);
        expect(m, greaterThanOrEqualTo(prev), reason: w);
        prev = m;
      }
    });
  });

  test('las tablas de colores y de metros cubren los mismos mundos', () {
    expect(worldConfigs.keys.toSet(), worldTrackMeters.keys.toSet());
  });

  group('isTutorialWorld', () {
    test('los dos mundos gratis arrancan con tutorial', () {
      expect(isTutorialWorld('brix_city'), isTrue);
      expect(isTutorialWorld('medieval'), isTrue);
    });
    test('los mundos avanzados no', () {
      expect(isTutorialWorld('robot_city'), isFalse);
      expect(isTutorialWorld('galaxy'), isFalse);
      expect(isTutorialWorld('no_existe'), isFalse);
    });
  });
}
