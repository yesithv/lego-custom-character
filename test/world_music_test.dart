import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/features/runner/domain/entities/world_music.dart';

void main() {
  group('Catálogo de música por mundo', () {
    test('cada mundo ofrece entre 3 y 4 pistas', () {
      for (final entry in worldMusicCatalog.entries) {
        expect(entry.value.length, inInclusiveRange(3, 4),
            reason: 'mundo ${entry.key}');
      }
    });

    test('cada pista tiene su propio fichero .wav existente en disco', () {
      for (final entry in worldMusicCatalog.entries) {
        for (final track in entry.value) {
          expect(track.asset, endsWith('.wav'),
              reason: '${entry.key} → ${track.name}');
          // AudioService reproduce con AssetSource('audio/$asset').
          final file = File('assets/audio/${track.asset}');
          expect(file.existsSync(), isTrue,
              reason: 'falta el audio ${file.path}');
        }
      }
    });

    test('no hay dos pistas que compartan el mismo fichero', () {
      final assets = <String>[];
      for (final tracks in worldMusicCatalog.values) {
        assets.addAll(tracks.map((t) => t.asset));
      }
      expect(assets.toSet().length, assets.length,
          reason: 'cada pista debe tener audio propio');
    });

    test('los nombres de pista son únicos dentro de cada mundo', () {
      for (final entry in worldMusicCatalog.entries) {
        final names = entry.value.map((t) => t.name).toSet();
        expect(names.length, entry.value.length,
            reason: 'nombres duplicados en ${entry.key}');
      }
    });

    test('cada pista tiene nombre, descripción y emoji', () {
      for (final tracks in worldMusicCatalog.values) {
        for (final track in tracks) {
          expect(track.name, isNotEmpty);
          expect(track.description, isNotEmpty);
          expect(track.emoji, isNotEmpty);
        }
      }
    });

    test('worldTracksFor devuelve el repertorio del mundo pedido', () {
      expect(worldTracksFor('medieval'), worldMusicCatalog['medieval']);
    });

    test('worldTracksFor usa Ciudad Brix como respaldo para un mundo desconocido',
        () {
      expect(worldTracksFor('mundo_inexistente'),
          worldMusicCatalog['brix_city']);
    });
  });
}
