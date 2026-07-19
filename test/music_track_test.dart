import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/features/character_editor/data/models/character_model.dart';
import 'package:run_for_win/features/character_editor/domain/entities/character.dart';
import 'package:run_for_win/features/character_editor/domain/entities/music_catalog.dart';

void main() {
  final now = DateTime(2026, 7, 12);
  Character baseChar(MusicTrack track) => Character(
        id: '1',
        name: 'DJ Brix',
        type: CharacterType.hero,
        appearance: const CharacterAppearance(),
        createdAt: now,
        updatedAt: now,
        musicTrack: track,
      );

  group('MusicTrack en la entidad', () {
    test('el valor por defecto es ratRave', () {
      final c = Character(
        id: '1',
        name: 'x',
        type: CharacterType.hero,
        appearance: const CharacterAppearance(),
        createdAt: now,
        updatedAt: now,
      );
      expect(c.musicTrack, MusicTrack.ratRave);
    });

    test('copyWith cambia solo la pista', () {
      final c = baseChar(MusicTrack.ratRave);
      final updated = c.copyWith(musicTrack: MusicTrack.chill);
      expect(updated.musicTrack, MusicTrack.chill);
      expect(updated.name, c.name);
      expect(updated.id, c.id);
    });

    test('dos personajes con distinta pista no son iguales', () {
      expect(baseChar(MusicTrack.neon), isNot(equals(baseChar(MusicTrack.chill))));
    });
  });

  group('Persistencia Hive (round-trip)', () {
    test('cada pista sobrevive fromEntity/toEntity', () {
      for (final track in MusicTrack.values) {
        final model = CharacterModel.fromEntity(baseChar(track));
        expect(model.musicTrack, track.index);
        expect(model.toEntity().musicTrack, track,
            reason: 'round-trip de $track');
      }
    });

    test('personaje antiguo sin campo (índice fuera de rango) cae a ratRave',
        () {
      // Simula un registro guardado con un índice inválido/no presente
      final legacy = CharacterModel(
        id: '1',
        name: 'viejo',
        type: 0,
        appearance: CharacterAppearanceModel.fromEntity(
            const CharacterAppearance()),
        createdAt: now,
        updatedAt: now,
        musicTrack: 999,
      );
      expect(legacy.toEntity().musicTrack, MusicTrack.ratRave);
    });
  });

  group('Catálogo de música', () {
    test('cada pista tiene metadatos y asetos únicos', () {
      final assets = <String>{};
      final names = <String>{};
      for (final track in MusicTrack.values) {
        final info = musicInfoFor(track);
        expect(info.asset, startsWith('music/'));
        expect(info.asset, endsWith('.mp3'));
        expect(info.name, isNotEmpty);
        assets.add(info.asset);
        names.add(info.name);
      }
      expect(assets.length, MusicTrack.values.length,
          reason: 'no hay assets duplicados');
      expect(names.length, MusicTrack.values.length,
          reason: 'no hay nombres duplicados');
    });
  });
}
