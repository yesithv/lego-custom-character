import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/core/l10n/app_localizations.dart';
import 'package:run_for_win/core/l10n/app_strings.dart';
import 'package:run_for_win/core/l10n/app_strings_extra.dart';
import 'package:run_for_win/features/character_editor/domain/entities/character.dart';
import 'package:run_for_win/features/missions/domain/entities/mission.dart';

void main() {
  group('resolveLanguage (detección del idioma del dispositivo)', () {
    test('elige un idioma soportado por su código', () {
      expect(AppLocalizations.resolveLanguage([const Locale('en')]), 'en');
      expect(AppLocalizations.resolveLanguage([const Locale('de')]), 'de');
      expect(AppLocalizations.resolveLanguage([const Locale('ru')]), 'ru');
      expect(AppLocalizations.resolveLanguage([const Locale('fr')]), 'fr');
    });

    test('ignora el país: pt_BR / pt_PT -> pt', () {
      expect(
        AppLocalizations.resolveLanguage([const Locale('pt', 'BR')]),
        'pt',
      );
      expect(
        AppLocalizations.resolveLanguage([const Locale('pt', 'PT')]),
        'pt',
      );
    });

    test('cae a español si el idioma no está soportado', () {
      expect(AppLocalizations.resolveLanguage([const Locale('it')]), 'es');
      expect(AppLocalizations.resolveLanguage([const Locale('ja')]), 'es');
      expect(AppLocalizations.resolveLanguage([]), 'es');
      expect(AppLocalizations.resolveLanguage(null), 'es');
    });

    test('respeta el orden de preferencia del dispositivo', () {
      // Primer idioma soportado gana, aunque haya otros después.
      expect(
        AppLocalizations.resolveLanguage(
            [const Locale('it'), const Locale('fr'), const Locale('en')]),
        'fr',
      );
    });
  });

  group('Búsqueda y reserva a español', () {
    test('devuelve el texto del idioma pedido', () {
      expect(AppLocalizations(const Locale('en')).tr('action_play'), 'PLAY!');
      expect(AppLocalizations(const Locale('fr')).tr('action_play'), 'JOUER !');
    });

    test('cae a español cuando la clave no existe en el idioma', () {
      // 'de' existe para esta clave; forzamos un idioma inexistente en el mapa.
      final l10n = AppLocalizations(const Locale('xx'));
      expect(l10n.tr('action_play'), kStrings['action_play']!['es']);
    });

    test('devuelve la propia clave si no existe en ningún idioma', () {
      expect(AppLocalizations(const Locale('en')).tr('clave_inexistente'),
          'clave_inexistente');
    });

    test('sustituye marcadores {clave}', () {
      final l10n = AppLocalizations(const Locale('en'));
      final out = l10n.trp('record_pts', {'pb': 1234});
      expect(out, contains('1234'));
      expect(out, isNot(contains('{pb}')));
    });
  });

  group('Helpers de contenido tipado', () {
    final en = AppLocalizations(const Locale('en'));

    test('tipos de personaje', () {
      expect(en.characterType(CharacterType.hero), 'Hero');
      expect(en.characterType(CharacterType.villain), 'Villain');
    });

    test('nombres y descripciones de mundo por id', () {
      expect(en.worldName('brix_city'), 'Brix City');
      expect(en.worldDescription('ocean'), isNotEmpty);
      expect(en.bossName('medieval'), 'Dark Dragon');
    });

    test('misión localizada por tipo + objetivo', () {
      const m = Mission(
        id: 'x',
        type: MissionType.collectCoins,
        title: 'Recolector',
        description: 'Recoge 10 monedas en una carrera',
        target: 10,
        progress: 0,
        rewardCoins: 50,
      );
      expect(en.missionTitle(m), 'Collector');
      expect(en.missionDescription(m), 'Collect 10 coins in one run');
    });
  });

  group('Consistencia de las tablas de traducción', () {
    const langs = kSupportedLanguages;

    test('cada clave tiene traducción en los 6 idiomas', () {
      for (final table in [kStrings, kStringsExtra]) {
        table.forEach((key, translations) {
          for (final lang in langs) {
            expect(
              translations[lang],
              isNotNull,
              reason: 'Falta la traducción "$lang" para la clave "$key"',
            );
            expect(
              translations[lang],
              isNotEmpty,
              reason: 'Traducción vacía "$lang" para la clave "$key"',
            );
          }
        });
      }
    });

    test('español (fuente/reserva) está presente en todas las claves', () {
      for (final table in [kStrings, kStringsExtra]) {
        table.forEach((key, translations) {
          expect(translations.containsKey(kFallbackLanguage), isTrue,
              reason: 'La clave "$key" no tiene español');
        });
      }
    });
  });
}
