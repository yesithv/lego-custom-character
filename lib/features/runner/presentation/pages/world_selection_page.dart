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
import '../../domain/entities/world_config.dart';

enum WorldStatus { available, locked }

class WorldData {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final Color color;
  final WorldStatus status;

  /// Etiquetas de zona/dificultad que se muestran en la tarjeta (solo para
  /// mundos disponibles). Ej. ['Inicio', 'Caos'].
  final List<String> tags;

  /// Coste en monedas para desbloquear el mundo (mundos bloqueados).
  final int unlockCost;

  const WorldData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.color,
    required this.status,
    this.tags = const [],
    this.unlockCost = 1000,
  });

  /// Longitud de la pista en metros. Vive en el dominio ([trackMetersFor])
  /// porque es exactamente la distancia a la que aparece el jefe: así lo que
  /// anuncia la tarjeta y lo que ocurre en la carrera no pueden desincronizarse.
  int get trackMeters => trackMetersFor(id);

  /// Texto para mostrar en la tarjeta, p. ej. "1200 m".
  String get trackLabel => '$trackMeters m';
}

const worlds = [
  WorldData(
    id: 'brix_city',
    name: 'Ciudad Brix',
    emoji: '🏙️',
    description: 'Calles de bloques, semáforos y autos.',
    color: Color(0xFF0055A5),
    status: WorldStatus.available,
    tags: ['Inicio', 'Caos'],
  ),
  WorldData(
    id: 'medieval',
    name: 'Reino Medieval',
    emoji: '🏰',
    description: 'Castillo, foso y catapultas.',
    color: Color(0xFF8B4513),
    status: WorldStatus.available,
    tags: ['Núcleo'],
  ),
  WorldData(
    id: 'galaxy',
    name: 'Galaxia Brix',
    emoji: '🚀',
    description: 'Estación espacial y asteroides.',
    color: Color(0xFF1A0A3B),
    status: WorldStatus.locked,
  ),
  WorldData(
    id: 'jungle',
    name: 'Jungla Salvaje',
    emoji: '🌿',
    description: 'Árboles de bloques, ríos y lianas.',
    color: Color(0xFF2D6A4F),
    status: WorldStatus.locked,
  ),
  WorldData(
    id: 'dark_city',
    name: 'Ciudad Oscura',
    emoji: '🕷️',
    description: 'Halloween, cementerio y niebla.',
    color: Color(0xFF1A1A2E),
    status: WorldStatus.locked,
  ),
  WorldData(
    id: 'ocean',
    name: 'Fondo del Mar',
    emoji: '🐙',
    description: 'Arrecifes de coral y burbujas.',
    color: Color(0xFF006994),
    status: WorldStatus.locked,
  ),
  WorldData(
    id: 'tundra',
    name: 'Tundra Helada',
    emoji: '❄️',
    description: 'Nieve, témpanos y ventisca.',
    color: Color(0xFF5BA4CF),
    status: WorldStatus.locked,
  ),
  WorldData(
    id: 'robot_city',
    name: 'Metrópolis Robot',
    emoji: '🤖',
    description: 'Fábricas, engranajes y pantallas.',
    color: Color(0xFF37474F),
    status: WorldStatus.locked,
  ),
];

class WorldSelectionPage extends StatelessWidget {
  /// Id del personaje a preseleccionar en los chips "CORREDOR" (viene de la
  /// Galería o del editor al pulsar "Jugar"). Null si se entra por ¡JUGAR!.
  final String? selectedCharacterId;

  const WorldSelectionPage({super.key, this.selectedCharacterId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CharacterEditorBloc>()..add(const LoadCharacters()),
      child: _WorldSelectionView(selectedCharacterId: selectedCharacterId),
    );
  }
}

class _WorldSelectionView extends StatefulWidget {
  final String? selectedCharacterId;
  const _WorldSelectionView({this.selectedCharacterId});

  @override
  State<_WorldSelectionView> createState() => _WorldSelectionViewState();
}

class _WorldSelectionViewState extends State<_WorldSelectionView> {
  /// Índice elegido manualmente por el usuario (null hasta que toca un chip).
  /// Mientras sea null se usa el personaje preseleccionado por id.
  int? _selectedCharacter;

  /// Índice efectivo del corredor: la elección manual si la hay; si no, el
  /// personaje preseleccionado por id; si no, el primero.
  int _effectiveIndex(List<Character> chars) {
    final manual = _selectedCharacter;
    if (manual != null) return manual.clamp(0, chars.length - 1);
    final id = widget.selectedCharacterId;
    if (id != null) {
      final idx = chars.indexWhere((c) => c.id == id);
      if (idx >= 0) return idx;
    }
    return 0;
  }

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
        child: SafeArea(
          child: BlocBuilder<CharacterEditorBloc, CharacterEditorState>(
            builder: (context, state) {
              final characters = state.characters;
              final selectedIndex =
                  characters.isEmpty ? 0 : _effectiveIndex(characters);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
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
                        const Text(
                          'Elige tu mundo',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (characters.isEmpty)
                    const Expanded(child: _NoCharactersState())
                  else ...[
                    // Etiqueta + chips de personaje (imagen + nombre debajo)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(
                          AppSpacing.horizontal, 4, AppSpacing.horizontal, 8),
                      child: Text(
                        'CORREDOR',
                        style: TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    _CharacterSelector(
                      characters: characters,
                      selectedIndex: selectedIndex,
                      onSelect: (i) =>
                          setState(() => _selectedCharacter = i),
                    ),
                    const SizedBox(height: 10),
                    // Lista de mundos (reacciona al modo de prueba en vivo)
                    Expanded(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: TestMode.instance.enabled,
                        builder: (context, _, __) => ListView.builder(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.horizontal,
                              4, AppSpacing.horizontal, 20),
                          itemCount: worlds.length,
                          itemBuilder: (context, i) => _WorldCard(
                            world: worlds[i],
                            character: characters[selectedIndex],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NoCharactersState extends StatelessWidget {
  const _NoCharactersState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.horizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🧱', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text(
              'Necesitas un personaje para jugar',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.goNamed('editor-new'),
              icon: const Icon(Icons.add),
              label: const Text('Crear personaje'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF3D2C00),
                minimumSize: const Size(200, 50),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CharacterSelector extends StatelessWidget {
  final List<Character> characters;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _CharacterSelector({
    required this.characters,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.horizontal),
        itemCount: characters.length,
        itemBuilder: (context, i) {
          final c = characters[i];
          final isSelected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 98,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFFD700).withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFFD700)
                      : Colors.white24,
                  width: isSelected ? 2.5 : 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CharacterPreview(appearance: c.appearance, size: 42),
                  const SizedBox(height: 2),
                  Text(
                    c.name.isEmpty ? '?' : c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WorldCard extends StatelessWidget {
  final WorldData world;
  final Character character;

  const _WorldCard({required this.world, required this.character});

  void _startRun(BuildContext context) {
    context.pushNamed(
      'pre-run',
      extra: {
        'character': character,
        'worldId': world.id,
        'worldName': world.name,
        'worldEmoji': world.emoji,
        'worldColor': world.color,
      },
    );
  }

  void _showLocked(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '¡Mundo bloqueado! Gana ${world.unlockCost} monedas para desbloquearlo.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // En modo de prueba todos los mundos quedan desbloqueados.
    final isLocked =
        world.status == WorldStatus.locked && !TestMode.instance.isOn;
    final lighter = Color.lerp(world.color, Colors.white, 0.14)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: isLocked ? () => _showLocked(context) : () => _startRun(context),
        child: Opacity(
          opacity: isLocked ? 0.7 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [lighter, world.color],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: world.color.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icono del mundo
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(world.emoji,
                        style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              world.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          if (isLocked) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.lock_rounded,
                                color: Colors.white, size: 16),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        world.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _DistancePill(text: world.trackLabel),
                          if (!isLocked)
                            ...world.tags.map((t) => _ZoneChip(t)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Acción a la derecha: jugar (disponible) o coste (bloqueado)
                if (isLocked)
                  _CoinCostPill(cost: world.unlockCost)
                else
                  const _PlayBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DistancePill extends StatelessWidget {
  final String text;
  const _DistancePill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.straighten_rounded, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneChip extends StatelessWidget {
  final String label;
  const _ZoneChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CoinCostPill extends StatelessWidget {
  final int cost;
  const _CoinCostPill({required this.cost});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$cost',
            style: const TextStyle(
              color: Color(0xFF3D2C00),
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC99700),
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: const Icon(Icons.directions_run_rounded,
          color: Color(0xFF3D2C00), size: 26),
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
      color: Colors.white.withValues(alpha: 0.10),
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
