import 'package:hive/hive.dart';

/// Persistencia mínima del progreso del tutorial guiado de controles.
///
/// Guarda cuántas veces se ha mostrado ya el tutorial en la caja Hive
/// `analytics_meta` (`Box<dynamic>`, ya abierta en `core/di/injection.dart`).
/// Se usa esa caja a propósito para **no gastar un typeId de Hive**: admite
/// valores arbitrarios sin adapter.
///
/// El tutorial solo aparece las primeras [maxTutorialRuns] carreras en las
/// pistas gratis; después el jugador ya conoce los controles y deja de salir.
class TutorialPrefs {
  TutorialPrefs._();

  static const String _boxName = 'analytics_meta';
  static const String _key = 'tutorial_seen_count';

  /// Número de carreras con tutorial que se muestran antes de desactivarlo.
  static const int maxTutorialRuns = 3;

  static Box<dynamic>? get _box =>
      Hive.isBoxOpen(_boxName) ? Hive.box<dynamic>(_boxName) : null;

  /// Cuántas veces se ha mostrado ya el tutorial (0 si nunca / caja cerrada).
  static int seenCount() => (_box?.get(_key) as int?) ?? 0;

  /// `true` si todavía toca mostrar el tutorial en esta carrera.
  static bool shouldShow() => seenCount() < maxTutorialRuns;

  /// Registra que el tutorial se mostró una vez más.
  static Future<void> incrementSeen() async {
    final box = _box;
    if (box == null) return;
    await box.put(_key, seenCount() + 1);
  }
}
