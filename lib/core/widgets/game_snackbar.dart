import 'package:flutter/material.dart';

/// Tipo de mensaje, define el color de acento del aviso.
enum GameSnackType { success, error, info }

/// Muestra un aviso (SnackBar) con el estilo visual de "Run For Win".
///
/// A diferencia de `ScaffoldMessenger.showSnackBar` directo, este helper:
///  - **limpia siempre el aviso anterior** antes de mostrar el nuevo, para que
///    un mensaje no se quede pintado ni se encole al navegar entre pantallas
///    (evita que el aviso siga visible ya dentro de la partida).
///  - usa una duración corta y coherente.
///  - aplica el estilo de bloques Brix: esquinas redondeadas, borde de acento,
///    icono, fondo oscuro del juego y tipografía Nunito en negrita.
void showGameSnackBar(
  BuildContext context,
  String message, {
  GameSnackType type = GameSnackType.info,
  Duration duration = const Duration(milliseconds: 2600),
}) {
  final (accent, icon) = switch (type) {
    GameSnackType.success => (const Color(0xFF3DDC84), Icons.check_circle_rounded),
    GameSnackType.error => (const Color(0xFFE94560), Icons.error_rounded),
    GameSnackType.info => (const Color(0xFFFFD700), Icons.info_rounded),
  };

  final messenger = ScaffoldMessenger.of(context)
    // Descarta cualquier aviso en curso o en cola: nada de mensajes zombis.
    ..clearSnackBars();

  messenger.showSnackBar(
    SnackBar(
      duration: duration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF152238), // azul noche del juego
      elevation: 8,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent, width: 2),
      ),
      content: Row(
        children: [
          Icon(icon, color: accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
