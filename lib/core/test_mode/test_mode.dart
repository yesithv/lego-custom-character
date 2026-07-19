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
class TestMode {
  TestMode._();

  /// Instancia única compartida por toda la app.
  static final TestMode instance = TestMode._();

  /// Estado on/off reactivo. Empieza apagado.
  final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);

  /// `true` si el modo de prueba está encendido.
  bool get isOn => enabled.value;

  /// Enciende o apaga el modo de prueba.
  set isOn(bool value) => enabled.value = value;

  /// Alterna el estado actual.
  void toggle() => enabled.value = !enabled.value;

  /// Longitud de pista (en metros) con el modo de prueba encendido: muy corta
  /// para que el jefe aparezca en pocos segundos.
  static const int shortTrackMeters = 20;

  /// Corazones del jefe con el modo de prueba encendido: uno solo, para
  /// derrotarlo con una única embestida y ver la pantalla de victoria.
  static const int weakBossHearts = 1;
}
