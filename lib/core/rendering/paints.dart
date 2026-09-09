import 'dart:ui';

/// `Paint` de relleno plano, memoizados por color.
///
/// Existe para el dibujo que ocurre en CADA frame y cuyos colores son fijos:
/// el escenario de los márgenes de la pista, por ejemplo, se dibuja una vez por
/// elemento vivo —media docena larga— y sus colores son constantes de código,
/// no dependen del mundo ni del elemento. Crear los `Paint` dentro del `render`
/// era medio centenar de instancias por frame para volver a construir siempre
/// exactamente las mismas.
///
/// **Por qué un mapa por color y no un `Paint` reutilizado que se muta:** con
/// un único `Paint` mutable, guardar la referencia en una variable y usarla en
/// dos llamadas con otro relleno en medio pinta la segunda con el color
/// equivocado. Es un fallo silencioso y fácil de introducir al editar. Aquí
/// cada color tiene su propio objeto, así que una referencia guardada sigue
/// siendo válida para siempre.
///
/// **Condición de uso:** llamar solo con colores de un conjunto acotado
/// (constantes o paletas fijas). El mapa no se purga, así que pasarle colores
/// calculados de forma continua lo haría crecer sin límite; para eso, construir
/// el `Paint` a mano. Mismo criterio que las memoizaciones de `lightenColor` y
/// `darkenColor`.
final Map<Color, Paint> _fillCache = {};

/// Devuelve el `Paint` de relleno de [color], compartido entre todas las
/// llamadas. No mutar el resultado: es el mismo objeto para todos.
Paint fillPaint(Color color) =>
    _fillCache.putIfAbsent(color, () => Paint()..color = color);
