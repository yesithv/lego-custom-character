import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/test_mode/test_mode.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../character_editor/domain/entities/character.dart';
import '../../../character_editor/presentation/bloc/character_editor_bloc.dart';
import '../../../character_editor/presentation/bloc/character_editor_event.dart';
import '../../../character_editor/presentation/bloc/character_editor_state.dart';
import '../../../character_editor/presentation/widgets/character_preview.dart';
import '../../../economy/presentation/bloc/wallet_bloc.dart';
import '../../../economy/presentation/bloc/wallet_state.dart';
import '../widgets/roulette_button.dart';
import '../../../runner/presentation/pages/world_selection_page.dart';

/// Pantalla principal enfocada en la carrera: el CTA dominante es "¡JUGAR!",
/// y el editor de personajes queda como acción secundaria.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CharacterEditorBloc>()..add(const LoadCharacters()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  /// Abre el ranking directamente (el primer mundo por defecto). La pantalla
  /// de ranking ya trae los chips para cambiar de mundo, así que no hace falta
  /// un selector previo.
  void _openRanking(BuildContext context) {
    final world = worlds.first;
    context.goNamed(
      'ranking',
      pathParameters: {'worldId': world.id},
      extra: {
        'worldName': world.name,
        'worldEmoji': world.emoji,
        'worldColor': world.color,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1466C8), Color(0xFF0A4A9E), Color(0xFF063574)],
          ),
        ),
        child: CustomPaint(
          painter: _DotGridPainter(),
          child: SafeArea(
            child: Padding(
              padding: AppSpacing.horizontalOnly,
              // El árbol reacciona en vivo al modo de prueba (banner + ruleta).
              child: ValueListenableBuilder<bool>(
                valueListenable: TestMode.instance.enabled,
                builder: (context, testOn, _) => Column(
                children: [
                  // Barra superior: monedas + ruleta diaria
                  Padding(
                    padding: const EdgeInsets.only(top: 32, bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HomeCoinBadge(),
                        const Spacer(),
                        BlocBuilder<WalletBloc, WalletState>(
                          builder: (context, walletState) => RouletteButton(
                            available:
                                walletState.wallet.canClaimRoulette,
                            onTap: () => context.goNamed('roulette'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Aviso del modo de prueba (solo cuando está encendido)
                  if (testOn)
                    _TestModeBanner(
                      onTap: () => _openTestModeSheet(context),
                    ),

                  const Spacer(flex: 2),

                  // Título compacto tipo píldora. Mantén pulsado para abrir el
                  // interruptor del modo de prueba.
                  _TitlePill(
                    onLongPress: () => _openTestModeSheet(context),
                  ),
                  const Spacer(flex: 2),

                  // Corredor activo sobre pedestal
                  const _ActiveCharacterCard(),
                  const Spacer(flex: 3),

                  // CTA principal: correr
                  _PlayButton(onTap: () => context.goNamed('worlds')),
                  const SizedBox(height: 20),

                  // Acciones secundarias en fila: personajes + ranking
                  Row(
                    children: [
                      Expanded(
                        child: _SecondaryTile(
                          icon: Icons.face_retouching_natural,
                          label: 'Mis personajes',
                          iconColor: Colors.white,
                          onTap: () => context.goNamed('gallery'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SecondaryTile(
                          icon: Icons.emoji_events_rounded,
                          label: 'Ver Ranking',
                          iconColor: const Color(0xFFFFD700),
                          onTap: () => _openRanking(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Hoja inferior con el interruptor del modo de prueba y el detalle de lo
  /// que desbloquea. Accesible manteniendo pulsado el título de la app.
  void _openTestModeSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0A2A55),
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _TestModeSheet(),
    );
  }
}

/// Botón principal "¡JUGAR!" con efecto 3D de bloque: base dorada sólida
/// debajo (sin blur) más una sombra suave. Se hunde ligeramente al pulsar.
class _PlayButton extends StatefulWidget {
  final VoidCallback onTap;
  const _PlayButton({required this.onTap});

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    // Al presionar, el botón baja y la base sólida se reduce → sensación de clic.
    final double drop = _pressed ? 3 : 7;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        width: double.infinity,
        height: 68,
        transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE24D), Color(0xFFFFCE1F)],
          ),
          boxShadow: [
            // Base dorada sólida (efecto bloque 3D)
            BoxShadow(
              color: const Color(0xFFC99700),
              offset: Offset(0, drop),
              blurRadius: 0,
            ),
            // Sombra suave de apoyo
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              offset: Offset(0, drop + 3),
              blurRadius: 12,
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow_rounded, size: 32, color: Color(0xFF3D2C00)),
            SizedBox(width: 8),
            Text(
              '¡JUGAR!',
              style: TextStyle(
                color: Color(0xFF3D2C00),
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Píldora de título con bandera a cuadros, como en el diseño.
///
/// Mantén pulsado para abrir el interruptor del modo de prueba ([onLongPress]).
class _TitlePill extends StatelessWidget {
  final VoidCallback? onLongPress;
  const _TitlePill({this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF063574).withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏁', style: TextStyle(fontSize: 22)),
            SizedBox(width: 10),
            Text(
              'RUN FOR WIN',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banda superior que avisa de que el modo de prueba está encendido.
class _TestModeBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _TestModeBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF7C4DFF).withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFB388FF), width: 1.5),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🧪', style: TextStyle(fontSize: 16)),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'MODO PRUEBA ACTIVO · todo desbloqueado',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Contenido de la hoja inferior del modo de prueba: interruptor + detalle.
class _TestModeSheet extends StatelessWidget {
  const _TestModeSheet();

  static const _perks = [
    ('🎡', 'Ruleta diaria siempre disponible'),
    ('🧩', 'Todos los accesorios de pago, gratis'),
    ('🗺️', 'Todos los mundos y pistas desbloqueados'),
    ('🏁', 'Pista súper corta: el jefe aparece enseguida'),
    ('💪', 'Jefe muy débil: derrótalo de un golpe'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
        child: ValueListenableBuilder<bool>(
          valueListenable: TestMode.instance.enabled,
          builder: (context, isOn, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🧪', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Modo de prueba',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Switch(
                    value: isOn,
                    activeThumbColor: const Color(0xFFB388FF),
                    onChanged: (v) => TestMode.instance.isOn = v,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                isOn
                    ? 'Encendido: se ignoran todas las limitaciones del juego.'
                    : 'Apagado: el juego funciona con sus reglas normales.',
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ..._perks.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.$1, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          p.$2,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Los cambios de pista y jefe se aplican en la próxima carrera.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón cuadrado de acción secundaria (personajes / ranking) con icono arriba.
class _SecondaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  const _SecondaryTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          // Base sólida para dar el mismo efecto 3D de bloque que el CTA.
          BoxShadow(
            color: const Color(0xFF042A5C),
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            offset: const Offset(0, 6),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            height: 74,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 24, color: iconColor),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
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

/// Patrón de puntos sutil sobre el fondo azul.
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.05);
    const spacing = 34.0;
    const radius = 3.0;
    for (double y = spacing; y < size.height; y += spacing) {
      for (double x = spacing; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Indicador de monedas del home: moneda dorada grande con el saldo debajo.
class _HomeCoinBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF063574).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFFFD700), width: 2),
            ),
            child: _coin(),
          ),
          const SizedBox(height: 4),
          Text(
            '${state.wallet.coins}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
              shadows: [
                Shadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coin() {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFFFF0A0), Color(0xFFFFD700), Color(0xFFD9A400)],
        ),
      ),
      child: Center(
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFB8860B).withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: const Center(
            child: Text(
              '\$',
              style: TextStyle(
                color: Color(0xFF9C6B00),
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveCharacterCard extends StatelessWidget {
  const _ActiveCharacterCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CharacterEditorBloc, CharacterEditorState>(
      builder: (context, state) {
        if (state.status == EditorStatus.loading) {
          return const SizedBox(
            height: 150,
            child: Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
          );
        }

        if (state.characters.isEmpty) {
          return GestureDetector(
            onTap: () => context.goNamed('editor-new'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🧱', style: TextStyle(fontSize: 40)),
                  SizedBox(height: 8),
                  Text(
                    'Crea tu corredor',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Necesitas un personaje para correr',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        final Character character = state.characters.first;
        return GestureDetector(
          onTap: () => context.goNamed('gallery'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CharacterStage(appearance: character.appearance),
              const SizedBox(height: 8),
              Text(
                character.name.isEmpty ? 'Sin nombre' : character.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  shadows: [
                    Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _CharacterTypeBadge(type: character.type),
            ],
          ),
        );
      },
    );
  }
}

/// Personaje sobre un pedestal dorado con halo, como en el diseño.
class _CharacterStage extends StatelessWidget {
  final CharacterAppearance appearance;

  const _CharacterStage({required this.appearance});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo suave detrás del personaje
          Container(
            width: 150,
            height: 150,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x3AFFD700), Color(0x00FFD700)],
              ),
            ),
          ),
          // Pedestal dorado (elipse plana)
          Positioned(
            bottom: 18,
            child: Container(
              width: 200,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFE24D), Color(0xFFE0A800)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          // Personaje apoyado sobre el pedestal
          Positioned(
            bottom: 26,
            child: CharacterPreview(appearance: appearance, size: 120),
          ),
        ],
      ),
    );
  }
}

/// Badge con el tipo de personaje (Héroe / Villano / …).
class _CharacterTypeBadge extends StatelessWidget {
  final CharacterType type;

  const _CharacterTypeBadge({required this.type});

  String get _label => switch (type) {
        CharacterType.hero => 'Héroe',
        CharacterType.villain => 'Villano',
        CharacterType.neutral => 'Neutral',
        CharacterType.mysterious => 'Misterioso',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white38, width: 1.5),
      ),
      child: Text(
        _label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}
