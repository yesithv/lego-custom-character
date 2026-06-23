import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../character_editor/domain/entities/character.dart';
import '../../../character_editor/presentation/widgets/character_preview.dart';

class PreRunPage extends StatelessWidget {
  final Character character;
  final String worldId;
  final String worldName;
  final String worldEmoji;
  final Color worldColor;

  const PreRunPage({
    super.key,
    required this.character,
    required this.worldId,
    required this.worldName,
    required this.worldEmoji,
    required this.worldColor,
  });

  static const _missions = [
    'Recoge 20 monedas en una carrera',
    'Esquiva 10 obstáculos seguidos',
    'Sobrevive más de 30 segundos',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [worldColor, worldColor.withValues(alpha: 0.7), Colors.black87],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    Text(
                      '$worldEmoji  $worldName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Character preview
              CharacterPreview(appearance: character.appearance, size: 120),
              const SizedBox(height: 8),
              Text(
                character.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 4),
              _CharacterTypeBadge(type: character.type),

              const SizedBox(height: 32),

              // Missions panel
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🎯  Misiones activas',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._missions.map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.radio_button_unchecked,
                                  color: Color(0xFFFFD700), size: 16),
                              const SizedBox(width: 8),
                              Text(m,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Run button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => context.goNamed(
                      'runner',
                      extra: {'character': character, 'worldId': worldId},
                    ),
                    child: const Text(
                      '¡CORRER!',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharacterTypeBadge extends StatelessWidget {
  final CharacterType type;
  const _CharacterTypeBadge({required this.type});

  static const _labels = {
    CharacterType.hero: ('Héroe', Colors.blue),
    CharacterType.villain: ('Villano', Colors.red),
    CharacterType.neutral: ('Neutral', Colors.grey),
    CharacterType.mysterious: ('Misterioso', Colors.purple),
  };

  @override
  Widget build(BuildContext context) {
    final (label, color) = _labels[type]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}
