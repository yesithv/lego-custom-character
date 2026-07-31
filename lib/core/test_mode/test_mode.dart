import 'package:flutter/foundation.dart';

/// Modo de prueba (uso interno / desarrollo).
///
/// Cuando está **encendido** desbloquea todas las limitaciones del juego para
/// poder probar cualquier pantalla en segundos:
/// - La ruleta diaria siempre se puede girar (sin esperar a mañana).
/// - Todos los accesorios de pago quedan disponibles gratis.
/// - Todos los mundos/pistas bloqueados quedan disponibles.
/// - La pista se hace súper corta: el jefe aparece casi de inmediato.
/// - El jefe es muy débil: un solo golpe basta para llegar a la victoria.
///
/// Es un interruptor global en memoria. Envuelve los widgets que deban
/// reaccionar en vivo con un [ValueListenableBuilder] sobre [enabled].
///
/// **Cómo se abre:** manteniendo pulsado el título "RUN FOR WIN" del Home
/// durante **10 segundos** seguidos, sin ninguna pista visual. Al desbloquear
/// contenido de pago, el atajo tiene que ser difícil de encontrar por accidente.
///
/// **Disponibilidad por tipo de build** (ver [isAvailable]): como el modo de
/// prueba desbloquea contenido de pago gratis, en la build de release que se
/// sube a Google Play queda **inerte** (no se puede activar): un usuario real no
/// debe poder saltarse las compras. Sigue funcionando en debug/profile y, para
/// probar un release firmado en tu dispositivo, se puede rehabilitar con el flag
/// de compilación `--dart-define=BRIX_TESTMODE=true`.
class TestMode {
  TestMode._();

  /// Instancia única compartida por toda la app.
  static final TestMode instance = TestMode._();

  /// Rehabilita el modo de prueba en builds de release cuando se compila con
  /// `--dart-define=BRIX_TESTMODE=true`. Por defecto `false` (la build de
  /// tienda no lo pasa), así el AAB publicado nunca lo permite.
  static const bool _allowedInRelease = bool.fromEnvironment('BRIX_TESTMODE');

  /// Estado on/off reactivo. Empieza apagado.
  final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);

  /// `true` si el modo de prueba puede activarse en esta build: siempre en
  /// debug/profile, y en release solo con el flag [_allowedInRelease]. Úsalo
  /// para ocultar los atajos de activación (p. ej. el pulsado largo del Home).
  bool get isAvailable => !kReleaseMode || _allowedInRelease;

  /// `true` si el modo de prueba está encendido.
  bool get isOn => enabled.value;

  /// Enciende o apaga el modo de prueba. En builds donde no está disponible
  /// (release sin el flag) es un no-op: nunca se puede encender.
  set isOn(bool value) {
    if (!isAvailable) return;
    enabled.value = value;
  }

  /// Alterna el estado actual. No hace nada si el modo no está disponible.
  void toggle() {
    if (!isAvailable) return;
    enabled.value = !enabled.value;
  }

  /// Longitud de pista (en metros) con el modo de prueba encendido: muy corta
  /// para que el jefe aparezca en pocos segundos.
  static const int shortTrackMeters = 20;

  /// Corazones del jefe con el modo de prueba encendido: uno solo, para
  /// derrotarlo con una única embestida y ver la pantalla de victoria.
  static const int weakBossHearts = 1;
}
