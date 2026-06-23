import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../character_editor/domain/entities/character.dart';
import '../../../character_editor/presentation/bloc/character_editor_bloc.dart';
import '../../../character_editor/presentation/bloc/character_editor_event.dart';
import '../../../character_editor/presentation/bloc/character_editor_state.dart';
import '../../../character_editor/presentation/widgets/character_preview.dart';
import '../../../ranking/presentation/bloc/ranking_bloc.dart';
import '../../../ranking/presentation/bloc/ranking_event.dart';

enum WorldStatus { available, locked }

class WorldData {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final Color color;
  final WorldStatus status;

  const WorldData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.color,
    required this.status,
  });
}

const _worlds = [
  WorldData(
    id: 'lego_city',
    name: 'Ciudad LEGO',
    emoji: '🏙️',
    description: 'Calles de bloques, semáforos y autos.',
    color: Color(0xFF0055A5),
    status: WorldStatus.available,
  ),
  WorldData(
    id: 'medieval',
    name: 'Reino Medieval',
    emoji: '🏰',
    description: 'Castillo, foso y catapultas.',
    color: Color(0xFF8B4513),
    status: WorldStatus.available,
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
  const WorldSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CharacterEditorBloc>()..add(const LoadCharacters()),
      child: const _WorldSelectionView(),
    );
  }
}

class _WorldSelectionView extends StatelessWidget {
  const _WorldSelectionView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD700),
        leading: BackButton(
          color: Colors.black87,
          onPressed: () => context.goNamed('gallery'),
        ),
        title: const Text(
          'Elige tu Mundo',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black87),
        ),
      ),
      body: BlocBuilder<CharacterEditorBloc, CharacterEditorState>(
        builder: (context, state) {
          final characters = state.characters;

          if (characters.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🧱', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  const Text(
                    'Necesitas un personaje para jugar',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.goNamed('editor-new'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black87,
                    ),
                    child: const Text('Crear personaje'),
                  ),
                ],
              ),
            );
          }

          // Character selector at top
          return Column(
            children: [
              _CharacterSelector(characters: characters),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _worlds.length,
                  itemBuilder: (context, i) => _WorldCard(
                    world: _worlds[i],
                    characters: characters,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CharacterSelector extends StatefulWidget {
  final List<Character> characters;
  const _CharacterSelector({required this.characters});

  @override
  State<_CharacterSelector> createState() => _CharacterSelectorState();
}

class _CharacterSelectorState extends State<_CharacterSelector> {
  int _selected = 0;

  Character get selectedCharacter => widget.characters[_selected];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8E0D0),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          const Text(
            'Elige tu personaje',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.characters.length,
              itemBuilder: (context, i) {
                final c = widget.characters[i];
                final isSelected = i == _selected;
                return GestureDetector(
                  onTap: () => setState(() => _selected = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFFD700)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFFD700)
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        CharacterPreview(
                            appearance: c.appearance, size: 40),
                        const SizedBox(height: 2),
                        Text(
                          c.name.isEmpty ? '?' : c.name,
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Store selected character in inherited widget so _WorldCard can access it
          _SelectedCharacterInherited(
            character: selectedCharacter,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// Simple InheritedWidget to pass selected character down
class _SelectedCharacterInherited extends InheritedWidget {
  final Character character;
  const _SelectedCharacterInherited(
      {required this.character, required super.child});

  static _SelectedCharacterInherited? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SelectedCharacterInherited>();

  @override
  bool updateShouldNotify(_SelectedCharacterInherited old) =>
      character != old.character;
}

class _WorldCard extends StatelessWidget {
  final WorldData world;
  final List<Character> characters;

  const _WorldCard({required this.world, required this.characters});

  @override
  Widget build(BuildContext context) {
    final isLocked = world.status == WorldStatus.locked;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: isLocked
            ? () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        '¡Mundo bloqueado! Gana monedas para desbloquearlo.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                )
            : () {
                final character = characters.first;
                context.goNamed(
                  'pre-run',
                  extra: {
                    'character': character,
                    'worldId': world.id,
                    'worldName': world.name,
                    'worldEmoji': world.emoji,
                    'worldColor': world.color,
                  },
                );
              },
        child: Opacity(
          opacity: isLocked ? 0.6 : 1.0,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: world.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: world.color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Text(world.emoji,
                        style: const TextStyle(fontSize: 48)),
                  ),
                ),
                if (!isLocked)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: GestureDetector(
                      onTap: () {
                        context.read<RankingBloc>().add(LoadRanking(world.id));
                        context.goNamed(
                          'ranking',
                          pathParameters: {'worldId': world.id},
                          extra: {
                            'worldName': world.name,
                            'worldEmoji': world.emoji,
                            'worldColor': world.color,
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.emoji_events_outlined,
                          color: Color(0xFFFFD700),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            world.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          if (isLocked) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.lock_rounded,
                                color: Colors.white70, size: 18),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        world.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      if (!isLocked) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _ZoneChip('Inicio'),
                            const SizedBox(width: 4),
                            _ZoneChip('Núcleo'),
                            const SizedBox(width: 4),
                            _ZoneChip('Zona Caos'),
                          ],
                        ),
                      ],
                    ],
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

class _ZoneChip extends StatelessWidget {
  final String label;
  const _ZoneChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
