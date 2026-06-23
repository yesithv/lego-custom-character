import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _worlds.length,
        itemBuilder: (context, i) => _WorldCard(world: _worlds[i]),
      ),
    );
  }
}

class _WorldCard extends StatelessWidget {
  final WorldData world;
  const _WorldCard({required this.world});

  @override
  Widget build(BuildContext context) {
    final isLocked = world.status == WorldStatus.locked;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: isLocked
            ? () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Mundo bloqueado! Gana monedas para desbloquearlo.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                )
            : () {
                // TODO: navigate to runner with world
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
                      if (!isLocked)
                        const SizedBox(height: 6),
                      if (!isLocked)
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
