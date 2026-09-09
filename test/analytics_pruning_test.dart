import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:run_for_win/features/analytics/data/datasources/analytics_local_datasource.dart';
import 'package:run_for_win/features/analytics/data/models/analytics_event_model.dart';

/// El log de analítica era append-only **sin tope**: cada carrera, cada
/// apertura de tienda y cada tirada de ruleta dejaban una fila para siempre, y
/// la caja se deserializa entera al abrir la app. A los meses de juego eso son
/// miles de eventos leídos en cada arranque.
///
/// Se prueba contra una caja de Hive de verdad (en un directorio temporal),
/// porque lo que se está fijando depende de su semántica real: claves
/// autoincrementales, `length` y `deleteAll`.
void main() {
  late Directory dir;
  late Box<AnalyticsEventModel> box;
  late AnalyticsLocalDatasourceImpl ds;

  const cap = AnalyticsLocalDatasourceImpl.maxEvents;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('run_for_win_analytics');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(AnalyticsEventModelAdapter());
    }
    box = await Hive.openBox<AnalyticsEventModel>('analytics_events');
    ds = AnalyticsLocalDatasourceImpl(
      events: box,
      meta: await Hive.openBox<dynamic>('analytics_meta'),
    );
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    await dir.delete(recursive: true);
  });

  Future<void> write(int n, {String name = 'evento'}) async {
    for (var i = 0; i < n; i++) {
      await ds.append(AnalyticsEventModel(name: '$name$i', tsMs: i));
    }
  }

  group('El log no crece sin límite', () {
    test('escribir muchos más eventos que el tope no desborda la caja',
        () async {
      await write(cap * 3);
      expect(box.length, lessThanOrEqualTo(cap + 100));
    });

    test('por debajo del tope no se borra nada', () async {
      await write(50);
      expect(box.length, 50);
      expect(ds.events().length, 50);
    });
  });

  group('Se conservan los eventos recientes', () {
    test('lo que sobrevive es la cola, no la cabeza', () async {
      await write(cap * 2, name: 'e');
      final kept = ds.events().map((e) => e.name).toList();

      // El último escrito siempre está; el primero, no.
      expect(kept, contains('e${cap * 2 - 1}'));
      expect(kept, isNot(contains('e0')));
    });

    test('los eventos quedan en orden de llegada', () async {
      await write(cap * 2, name: 'e');
      final indices = ds
          .events()
          .map((e) => int.parse(e.name.substring(1)))
          .toList();

      expect(indices, orderedEquals([...indices]..sort()));
    });
  });

  group('La poda no toca los metadatos', () {
    test('sesiones, primer uso y días activos sobreviven al recorte', () async {
      // Son los agregados que de verdad importan y viven en la otra caja.
      await ds.setSessions(42);
      await ds.setFirstOpenMs(1234);
      await ds.setActiveDays(['2026-01-01', '2026-01-02']);

      await write(cap * 2);

      expect(ds.sessions, 42);
      expect(ds.firstOpenMs, 1234);
      expect(ds.activeDays, ['2026-01-01', '2026-01-02']);
    });
  });

  group('Instalaciones que ya venían infladas', () {
    test('una caja heredada con exceso se recorta al primer evento nuevo',
        () async {
      // Simula el log de un jugador de meses, escrito antes de que hubiera
      // tope: la primera escritura tras actualizar debe dejarlo acotado.
      for (var i = 0; i < cap * 4; i++) {
        await box.add(AnalyticsEventModel(name: 'viejo$i', tsMs: i));
      }
      expect(box.length, cap * 4);

      await ds.append(AnalyticsEventModel(name: 'nuevo', tsMs: 0));

      expect(box.length, cap);
      expect(ds.events().last.name, 'nuevo');
    });
  });
}
