import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/character.dart';
import '../bloc/character_editor_bloc.dart';
import '../bloc/character_editor_event.dart';
import '../bloc/character_editor_state.dart';
import '../widgets/character_preview.dart';

class CharacterGalleryPage extends StatelessWidget {
  const CharacterGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CharacterEditorBloc>()..add(const LoadCharacters()),
      child: const _GalleryView(),
    );
  }
}

class _GalleryView extends StatelessWidget {
  const _GalleryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF063574),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1466C8), Color(0xFF0A4A9E), Color(0xFF063574)],
          ),
        ),
        child: CustomPaint(
          painter: _DotsPainter(),
          child: SafeArea(
            child: Column(
              children: [
                // Header: volver + título + nuevo
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.horizontal, 12, AppSpacing.horizontal, 8),
                  child: Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => context.goNamed('home'),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Mis personajes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            shadows: [
                              Shadow(
                                color: Colors.black38,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _NewButton(onTap: () => _openNewEditor(context)),
                    ],
                  ),
                ),

                // Grid de personajes
                Expanded(
                  child: BlocBuilder<CharacterEditorBloc, CharacterEditorState>(
                    builder: (context, state) {
                      if (state.status == EditorStatus.loading) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }

                      if (state.characters.isEmpty) {
                        return _EmptyState(
                          onCreateTap: () => _openNewEditor(context),
                          onPresetsTap: () => context.goNamed('presets'),
                        );
                      }

                      // Siempre 2 columnas, centradas y con un ancho máximo
                      // para que en web no queden tarjetas gigantes.
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 430),
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.horizontal,
                                8, AppSpacing.horizontal, 12),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.54,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                            itemCount: state.characters.length,
                            itemBuilder: (context, i) {
                              final character = state.characters[i];
                              return _CharacterCard(
                                character: character,
                                // El primer personaje es el "corredor activo"
                                // que aparece en el home (ver HomePage).
                                isActive: i == 0,
                                onEdit: () => context.goNamed(
                                  'editor-edit',
                                  pathParameters: {'id': character.id},
                                ),
                                onDelete: () =>
                                    _confirmDelete(context, character),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Botón inferior: personajes precargados
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.horizontal, 8, AppSpacing.horizontal, 16),
                  child: _PresetsButton(
                    onTap: () => context.goNamed('presets'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openNewEditor(BuildContext context) {
    context.read<CharacterEditorBloc>().add(const StartNewCharacter());
    context.goNamed('editor-new');
  }

  void _confirmDelete(BuildContext context, Character character) {
    final bloc = context.read<CharacterEditorBloc>();
    final name = character.name.isEmpty ? 'este personaje' : character.name;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF152238),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminar personaje',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: Text(
          '¿Seguro que quieres eliminar $name? Esta acción no se puede deshacer.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE94560),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              bloc.add(DeleteCharacterById(character.id));
              Navigator.pop(dialogContext);
            },
            child: const Text('Eliminar',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

// ── Character card ───────────────────────────────────────────────────────────

class _CharacterCard extends StatelessWidget {
  final Character character;
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CharacterCard({
    required this.character,
    required this.isActive,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(character.type);
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.16),
              Colors.white.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFFFFD700) : Colors.white24,
            width: isActive ? 2.5 : 1.5,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.30),
                blurRadius: 16,
                spreadRadius: 1,
              )
            else
              BoxShadow(
                color: const Color(0xFF042A5C).withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // Figura sobre una plataforma tenue
                Expanded(
                  child: Center(
                    child: _CharacterStand(appearance: character.appearance),
                  ),
                ),
                // Nombre
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    character.name.isEmpty ? 'Sin nombre' : character.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 6),
                // Badge de tipo
                _TypeBadge(label: _typeLabel(character.type), color: typeColor),
                const SizedBox(height: 10),
                // Acciones: editar + eliminar
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionChip(
                      icon: Icons.edit_rounded,
                      color: const Color(0xFFFFD700),
                      onTap: onEdit,
                      tooltip: 'Editar',
                    ),
                    const SizedBox(width: 10),
                    _ActionChip(
                      icon: Icons.delete_outline_rounded,
                      color: const Color(0xFFFF6B81),
                      onTap: onDelete,
                      tooltip: 'Eliminar',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
            // Badge "ACTIVO"
            if (isActive)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'ACTIVO',
                    style: TextStyle(
                      color: Color(0xFF3D2C00),
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Figura del personaje con una plataforma tenue debajo.
class _CharacterStand extends StatelessWidget {
  final CharacterAppearance appearance;

  const _CharacterStand({required this.appearance});

  // Tamaño fijo de la figura. Se le da una caja acotada (la figura mide
  // size*1.6 de alto) para que nunca invada el nombre debajo.
  static const double _figSize = 92;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _figSize * 1.1,
      height: _figSize * 1.6 + 8,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Plataforma tenue bajo los pies
          Positioned(
            bottom: 2,
            child: Container(
              width: _figSize * 1.05,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.22),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            child: CharacterPreview(appearance: appearance, size: _figSize),
          ),
        ],
      ),
    );
  }
}

// ── Small UI pieces ──────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TypeBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionChip({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: 40,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _NewButton extends StatelessWidget {
  final VoidCallback onTap;

  const _NewButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC99700),
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: const Color(0xFFFFD700),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Color(0xFF3D2C00), size: 20),
                SizedBox(width: 4),
                Text(
                  'Nuevo',
                  style: TextStyle(
                    color: Color(0xFF3D2C00),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
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

class _PresetsButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PresetsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFD700).withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFFFFD700), size: 20),
              SizedBox(width: 8),
              Text(
                'Ver personajes precargados',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateTap;
  final VoidCallback onPresetsTap;
  const _EmptyState({required this.onCreateTap, required this.onPresetsTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.horizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🧱', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              '¡Crea tu primer personaje!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Diseña tu minifigura y úsala en el runner.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add),
              label: const Text('Crear personaje'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF3D2C00),
                minimumSize: const Size(220, 52),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onPresetsTap,
              icon: const Icon(Icons.auto_awesome, color: Color(0xFFFFD700)),
              label: const Text('Ver personajes precargados'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size(220, 52),
                side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

String _typeLabel(CharacterType type) => switch (type) {
      CharacterType.hero => 'Héroe',
      CharacterType.villain => 'Villano',
      CharacterType.neutral => 'Neutral',
      CharacterType.mysterious => 'Misterioso',
    };

Color _typeColor(CharacterType type) => switch (type) {
      CharacterType.hero => const Color(0xFF4A90E2),
      CharacterType.villain => const Color(0xFFEC407A),
      CharacterType.neutral => const Color(0xFF2ECC71),
      CharacterType.mysterious => const Color(0xFFB07CE8),
    };

/// Patrón de puntos sutil sobre el fondo azul (igual que el home).
class _DotsPainter extends CustomPainter {
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
