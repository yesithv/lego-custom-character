import 'package:flutter_test/flutter_test.dart';
import 'package:lego_custom_character/features/runner/domain/entities/world_music.dart';

void main() {
  // Assets de audio realmente disponibles bajo assets/audio/.
  const availableAssets = {
    'music/rat_rave.mp3',
    'music/neon.mp3',
    'music/chiptune.mp3',
    'music/chill.mp3',
  };

  group('Catálogo de música por mundo', () {
    test('cada mundo ofrece entre 3 y 4 pistas', () {
      for (final entry in worldMusicCatalog.entries) {
        expect(entry.value.length, inInclusiveRange(3, 4),
            reason: 'mundo ${entry.key}');
      }
    });

    test('todas las pistas apuntan a un asset existente', () {
      for (final entry in worldMusicCatalog.entries) {
        for (final track in entry.value) {
          expect(availableAssets, contains(track.asset),
              reason: '${entry.key} → ${track.name}');
        }
      }
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

    test('worldTracksFor usa Ciudad LEGO como respaldo para un mundo desconocido',
        () {
      expect(worldTracksFor('mundo_inexistente'),
          worldMusicCatalog['lego_city']);
    });
  });
}
