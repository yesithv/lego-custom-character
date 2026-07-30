import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';

/// Bloqueo de orientación **vertical** (portrait) de Run For Win.
///
/// El juego está diseñado para jugarse en vertical (pista de 3 carriles, HUD
/// arriba y controles por gestos). Si el jugador abre la app con el teléfono en
/// horizontal, la pantalla debe verse igualmente en vertical.
///
/// Se cubre en tres capas, porque ninguna sirve para todas las plataformas:
///
/// 1. **Nativo (Android/iOS):** [lockPortraitOrientation] fija la orientación
///    del dispositivo. En Android el `AndroidManifest.xml` ya declara
///    `android:screenOrientation="portrait"`, así que la app arranca vertical
///    incluso antes del primer frame de Flutter; esta llamada añade el bloqueo
///    del lado de Flutter (y cubre iOS, cuyo proyecto se genera al construir).
/// 2. **PWA instalada (web):** `web/manifest.json` declara
///    `"orientation": "portrait-primary"`, y `web/index.html` intenta
///    `screen.orientation.lock('portrait')`.
/// 3. **Navegador móvil (web):** ahí no se puede rotar la pantalla por código,
///    así que [PortraitGate] tapa el juego con un aviso de "gira el teléfono"
///    mientras el dispositivo esté en horizontal.
///
/// Fija la orientación del dispositivo a vertical.
///
/// Llamar una sola vez, antes de `runApp`. En web no hace nada: el navegador
/// no permite rotar la pantalla desde el motor de Flutter (ver [PortraitGate]).
Future<void> lockPortraitOrientation() async {
  if (kIsWeb) return;
  // Solo `portraitUp`: igual que el manifest de Android, para que la interfaz
  // no se ponga boca abajo si el niño gira el teléfono 180°.
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
}

/// `true` mientras [PortraitGate] está tapando el juego porque la pantalla
/// está en horizontal.
///
/// Lo usan las pantallas de gameplay (ver `RunnerPage`) para pausarse mientras
/// el jugador no puede ver la partida, y reanudar al volver a vertical.
final ValueNotifier<bool> landscapeBlocked = ValueNotifier<bool>(false);

/// Decide si hay que pedirle al jugador que gire el dispositivo.
///
/// Solo en teléfonos: en escritorio (incluida la web en escritorio) la ventana
/// es horizontal por naturaleza y ahí el juego se muestra tal cual.
bool shouldAskToRotate({
  required Size size,
  required TargetPlatform platform,
}) {
  final isMobile =
      platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  if (!isMobile) return false;
  // Ya está en vertical (o es cuadrada): nada que hacer.
  if (size.width <= size.height) return false;
  return size.shortestSide < PortraitGate.phoneMaxShortestSide;
}

/// Envuelve la app y, en teléfonos en horizontal, tapa el juego con un aviso
/// para que lo gire a vertical.
///
/// En nativo prácticamente no se ve (la orientación está bloqueada); su motivo
/// real es la web móvil, donde el navegador ignora cualquier bloqueo de
/// orientación si la app no está instalada como PWA.
///
/// El árbol de la app sigue **montado** debajo del aviso: al volver a vertical
/// el jugador retoma justo donde estaba, sin perder la partida ni el estado.
class PortraitGate extends StatelessWidget {
  const PortraitGate({super.key, required this.child});

  final Widget child;

  /// Lado corto máximo (en dp) para considerar la pantalla un teléfono.
  /// 600 dp es el corte habitual de Material entre teléfono y tablet.
  static const double phoneMaxShortestSide = 600;

  @override
  Widget build(BuildContext context) {
    final blocked = shouldAskToRotate(
      size: MediaQuery.sizeOf(context),
      platform: defaultTargetPlatform,
    );
    // Se avisa tras el frame: quien escucha (el runner) llama a `setState`.
    if (landscapeBlocked.value != blocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        landscapeBlocked.value = blocked;
      });
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        // `AbsorbPointer` evita que los toques lleguen al juego tapado.
        if (blocked) const AbsorbPointer(child: _RotateDeviceOverlay()),
      ],
    );
  }
}

/// Aviso a pantalla completa: "gira el teléfono".
class _RotateDeviceOverlay extends StatefulWidget {
  const _RotateDeviceOverlay();

  @override
  State<_RotateDeviceOverlay> createState() => _RotateDeviceOverlayState();
}

class _RotateDeviceOverlayState extends State<_RotateDeviceOverlay>
    with SingleTickerProviderStateMixin {
  static const _background = Color(0xFF1A1A2E); // igual que el fondo web
  static const _accent = Color(0xFFFFD700); // Brix yellow

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // La app puede no tener `Directionality` por encima del `builder`.
    return Directionality(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: Material(
        color: _background,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RotationTransition(
                  // Gira el icono un cuarto de vuelta, de ida y vuelta.
                  turns: Tween<double>(begin: 0, end: 0.25).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: const Icon(
                    Icons.stay_current_portrait,
                    size: 88,
                    color: _accent,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  l10n.tr('rotate_device_title'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.tr('rotate_device_hint'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
