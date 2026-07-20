import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../features/character_editor/domain/entities/character.dart';
import '../../features/economy/domain/entities/part_catalog.dart';
import '../../features/missions/domain/entities/mission.dart';
import 'app_strings.dart';
import 'app_strings_extra.dart';

/// Localización de Run For Win, escrita a mano (sin generadores).
///
/// - Detecta el idioma del dispositivo y carga uno de los idiomas soportados.
/// - Si el idioma del dispositivo no está soportado, usa **español** por defecto.
/// - Cualquier clave sin traducir cae a español y, si tampoco existe, a la clave.
///
/// Además de la API basada en `BuildContext` ([AppLocalizations.of]), expone un
/// acceso global [L10n] para la capa del juego (componentes de Flame que no
/// tienen `BuildContext`).
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  String get languageCode => locale.languageCode;

  /// Idiomas soportados como [Locale], en orden de preferencia.
  static const List<Locale> supportedLocales = [
    Locale('es'),
    Locale('en'),
    Locale('pt'),
    Locale('de'),
    Locale('ru'),
    Locale('fr'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    // En pruebas o pantallas sin delegado, cae al idioma global activo.
    return l10n ?? AppLocalizations(Locale(L10n.language));
  }

  /// Elige el código de idioma soportado a partir de la lista de idiomas del
  /// dispositivo (en orden de preferencia). Devuelve [kFallbackLanguage]
  /// (español) si ninguno coincide. La comparación es solo por `languageCode`,
  /// así que `pt_BR`, `pt_PT`, etc. mapean todos a `pt`.
  static String resolveLanguage(Iterable<Locale>? deviceLocales) {
    if (deviceLocales != null) {
      for (final locale in deviceLocales) {
        if (kSupportedLanguages.contains(locale.languageCode)) {
          return locale.languageCode;
        }
      }
    }
    return kFallbackLanguage;
  }

  // ── Búsqueda de texto ──────────────────────────────────────────────────────

  /// Traduce [key] al idioma actual. Cae a español y luego a la propia clave.
  String tr(String key) => L10n.lookup(key, languageCode);

  /// Como [tr], sustituyendo marcadores `{clave}` por [params].
  String trp(String key, Map<String, Object?> params) =>
      L10n.substitute(tr(key), params);

  // ── Helpers de contenido tipado ────────────────────────────────────────────

  String characterType(CharacterType type) => tr('type_${type.name}');

  String rarity(AccessoryRarity r) => tr('rarity_${r.name}');

  String worldName(String worldId) => tr('world_${worldId}_name');
  String worldDescription(String worldId) => tr('world_${worldId}_desc');
  String bossName(String worldId) => tr('boss_$worldId');

  /// Traduce una etiqueta de zona de las tarjetas de mundo (guardadas en
  /// español como 'Inicio' / 'Núcleo' / 'Caos').
  String worldTag(String esTag) {
    switch (esTag) {
      case 'Inicio':
        return tr('tag_start');
      case 'Núcleo':
        return tr('tag_core');
      case 'Caos':
        return tr('tag_chaos');
      default:
        return esTag;
    }
  }

  /// Nombre localizado de un accesorio del catálogo. Cae al nombre en español
  /// del propio [CatalogEntry] si no hay traducción.
  String partName(CatalogEntry entry) {
    final translated = L10n.lookupOrNull('part_${entry.id}', languageCode);
    return translated ?? entry.name;
  }

  /// Título localizado de una misión (a partir de su tipo + objetivo, que sí se
  /// conservan; el texto guardado en Hive puede estar en otro idioma).
  String missionTitle(Mission m) {
    final key = 'mission_title_${m.type.name}_${m.target}';
    return L10n.lookupOrNull(key, languageCode) ?? m.title;
  }

  /// Descripción localizada de una misión.
  String missionDescription(Mission m) {
    final tpl = L10n.lookupOrNull('mission_desc_${m.type.name}', languageCode);
    if (tpl == null) return m.description;
    return L10n.substitute(tpl, {'n': m.target});
  }

  String storeProductTitle(String id, String fallback) =>
      L10n.lookupOrNull('product_${id}_t', languageCode) ?? fallback;
  String storeProductDescription(String id, String fallback) =>
      L10n.lookupOrNull('product_${id}_d', languageCode) ?? fallback;
}

/// Acceso global al idioma activo y a la tabla de traducciones.
///
/// Pensado para código sin `BuildContext` (motor de juego). Se mantiene en
/// sincronía con [MaterialApp] mediante el delegado, que fija [language] cada
/// vez que se carga un locale.
class L10n {
  L10n._();

  /// Código de idioma activo (uno de [kSupportedLanguages]).
  static String language = kFallbackLanguage;

  /// Traduce una clave a [lang], cayendo a español y luego a la clave.
  static String lookup(String key, String lang) {
    return lookupOrNull(key, lang) ?? key;
  }

  /// Como [lookup], pero devuelve `null` si la clave no existe en ningún idioma.
  static String? lookupOrNull(String key, String lang) {
    final entry = kStrings[key] ?? kStringsExtra[key];
    if (entry == null) return null;
    return entry[lang] ?? entry[kFallbackLanguage];
  }

  /// Traducción global rápida para la capa del juego.
  static String t(String key) => lookup(key, language);

  /// Traducción global con sustitución de marcadores `{clave}`.
  static String tp(String key, Map<String, Object?> params) =>
      substitute(t(key), params);

  /// Sustituye marcadores `{clave}` en [template] por [params].
  static String substitute(String template, Map<String, Object?> params) {
    var out = template;
    params.forEach((k, v) => out = out.replaceAll('{$k}', '${v ?? ''}'));
    return out;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      kSupportedLanguages.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    // Normaliza al código soportado (o español) y publícalo globalmente.
    final lang = kSupportedLanguages.contains(locale.languageCode)
        ? locale.languageCode
        : kFallbackLanguage;
    L10n.language = lang;
    return SynchronousFuture<AppLocalizations>(AppLocalizations(Locale(lang)));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Azúcar sintáctico: `context.l10n.tr('clave')`.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
