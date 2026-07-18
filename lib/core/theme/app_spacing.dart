import 'package:flutter/widgets.dart';

/// Espaciado estándar de las pantallas (equivalente a un "CSS" compartido).
///
/// Define el margen de borde (padding en X e Y) que deben respetar todas las
/// pantallas del juego **excepto la de correr** (`RunnerPage`), que ocupa todo
/// el alto/ancho para el gameplay y no debe llevar estos márgenes.
///
/// Uso típico:
/// ```dart
/// Padding(
///   padding: AppSpacing.screen,
///   child: ...,
/// )
/// ```
class AppSpacing {
  AppSpacing._();

  /// Margen horizontal a los lados del contenido.
  static const double horizontal = 24;

  /// Margen superior del contenido.
  static const double top = 24;

  /// Margen inferior del contenido.
  static const double bottom = 28;

  /// Padding de borde completo (lados + arriba + abajo). Para el contenido
  /// principal de una pantalla dentro de un `SafeArea`.
  static const EdgeInsets screen = EdgeInsets.fromLTRB(
    horizontal,
    top,
    horizontal,
    bottom,
  );

  /// Solo padding horizontal (lados). Útil cuando el eje vertical lo maneja
  /// otro widget (listas, `AppBar`, etc.).
  static const EdgeInsets horizontalOnly =
      EdgeInsets.symmetric(horizontal: horizontal);

  /// Padding para contenido desplazable (listas/scroll) con algo más de aire
  /// abajo para que el último elemento no quede pegado al borde.
  static const EdgeInsets scrollContent = EdgeInsets.fromLTRB(
    horizontal,
    top,
    horizontal,
    bottom + 12,
  );
}
