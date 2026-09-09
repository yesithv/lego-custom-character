import 'dart:ui' show Offset;

/// Los cuatro controles del corredor que un gesto puede producir.
enum SwipeAction { left, right, up, down }

/// Reconocedor de swipes de la partida.
///
/// **Por qué existe como clase aparte:** la política del gesto (cuándo un
/// arrastre cuenta como swipe, cuándo puede encadenar otro, cuándo se cae al
/// flick por velocidad) es lógica de verdad, con casos límite que conviene
/// fijar con tests. Sacarla del `State` permite probarla sin montar la página
/// entera —que arrastra Hive, blocs y el motor— y deja el `GestureDetector`
/// reducido a cablear tres llamadas.
///
/// **Decisión de diseño clave: se resuelve en [update], no en [end].**
/// Decidir el swipe al levantar el dedo metía entre el gesto y el movimiento
/// todo lo que el dedo tardase en despegarse (fácilmente 200-400 ms en un niño
/// que arrastra despacio). Ese silencio se percibía como si el juego se
/// congelara, aunque fuese a 60 fps limpios. Resolviéndolo en vuelo, el
/// corredor sale en el mismo frame en que el dedo cruza el umbral.
///
/// **Por desplazamiento, no por velocidad.** Un arrastre lento termina con
/// velocidad ≈ 0; leerlo por velocidad no registraría nada. La velocidad solo
/// se usa como red de seguridad para el flick corto y rápido, que se levanta
/// antes de recorrer el umbral (ver [end]).
class SwipeDetector {
  /// Desplazamiento (px) que dispara la PRIMERA acción de un arrastre.
  final double minDistance;

  /// Desplazamiento adicional para encadenar la SIGUIENTE acción dentro del
  /// mismo arrastre, sin levantar el dedo (cruzar dos carriles de una pasada).
  /// Mayor que [minDistance] a propósito: tras un cambio de carril el dedo casi
  /// siempre sigue derivando un poco, y ese resto no debe contar como otro
  /// swipe.
  final double repeatDistance;

  /// Velocidad (px/s) a partir de la cual un flick corto cuenta como swipe.
  final double flickVelocity;

  /// Punto desde el que se mide el desplazamiento que falta para la siguiente
  /// acción. Se re-ancla tras cada acción disparada. `null` = no hay gesto.
  Offset? _anchor;

  /// Si el gesto en curso ya disparó alguna acción.
  bool _fired = false;

  SwipeDetector({
    this.minDistance = 24.0,
    this.repeatDistance = 44.0,
    this.flickVelocity = 40.0,
  });

  /// Si hay un gesto en curso (entre [start] y [end]/[cancel]).
  bool get isTracking => _anchor != null;

  /// Si el gesto en curso ya produjo alguna acción.
  bool get hasFired => _fired;

  /// Empieza a seguir un arrastre desde [position].
  void start(Offset position) {
    _anchor = position;
    _fired = false;
  }

  /// Procesa un punto intermedio del arrastre. Devuelve la acción a ejecutar si
  /// el dedo acaba de cruzar el umbral, o `null` si aún no hay nada que hacer.
  SwipeAction? update(Offset position) {
    final anchor = _anchor;
    if (anchor == null) return null;

    final delta = position - anchor;
    final threshold = _fired ? repeatDistance : minDistance;
    if (delta.distance < threshold) return null;

    _fired = true;
    // Re-anclar aquí: lo que el dedo recorra a partir de este punto se mide
    // desde cero, así que un arrastre largo encadena movimientos.
    _anchor = position;
    return _resolve(delta.dx, delta.dy);
  }

  /// Cierra el gesto. Devuelve una acción SOLO si el arrastre no llegó a
  /// disparar nada en vuelo y se levantó como un flick rápido; en cualquier
  /// otro caso devuelve `null` (el jugador ya tuvo su respuesta durante el
  /// arrastre, repetirla aquí duplicaría el movimiento).
  SwipeAction? end(Offset velocity) {
    final fired = _fired;
    _anchor = null;
    _fired = false;
    if (fired) return null;

    if (velocity.dx.abs() <= flickVelocity &&
        velocity.dy.abs() <= flickVelocity) {
      return null;
    }
    return _resolve(velocity.dx, velocity.dy);
  }

  /// Descarta el gesto en curso sin producir acción (p. ej. al pausar).
  void cancel() {
    _anchor = null;
    _fired = false;
  }

  /// El eje dominante decide el control: horizontal → carril, vertical → salto
  /// o agachado.
  static SwipeAction _resolve(double dx, double dy) {
    if (dx.abs() > dy.abs()) {
      return dx > 0 ? SwipeAction.right : SwipeAction.left;
    }
    return dy < 0 ? SwipeAction.up : SwipeAction.down;
  }
}
